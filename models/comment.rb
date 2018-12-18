class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :account, index: true
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true

  field :subject, :type => String  
  field :body, :type => String 
  field :file_uid, :type => String
  
  dragonfly_accessor :file  
  
  validates_presence_of :body
    
  has_many :comment_likes, :dependent => :destroy
  has_many :options, :dependent => :destroy
  has_many :read_receipts, :dependent => :destroy
  
  after_create do
    post.subscriptions.create account: account
  end

  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account and commentable.respond_to?(:group)
      notifications.create! :group => commentable.group, :type => 'commented'
    end
  end  
    
  after_create do
    if ENV['PUSHER_APP_ID']
      pusher_client = Pusher::Client.new(app_id: ENV['PUSHER_APP_ID'], key: ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], cluster: ENV['PUSHER_CLUSTER'], encrypted: true)
      pusher_client.trigger("post.#{post.id}", 'updated', {})
    end
  end
  
  after_destroy do
    if ENV['PUSHER_APP_ID']
      pusher_client = Pusher::Client.new(app_id: ENV['PUSHER_APP_ID'], key: ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], cluster: ENV['PUSHER_CLUSTER'], encrypted: true)
      pusher_client.trigger("post.#{post.id}", 'updated', {})
    end
  end  
    
  before_validation do
    self.commentable = self.post.commentable if self.post
  end   
  
  def description
    if commentable.is_a?(Mapplication)
      "<strong>#{account.name}</strong> commented on <strong>#{commentable.account.name}</strong>'s application"                  
    else
      if post.comments.count == 1
        "<strong>#{account.name}</strong> posted in <strong>#{commentable.name}</strong>"                  
      else
        "<strong>#{account.name}</strong> replied to a thread in <strong>#{commentable.name}</strong>"                  
      end
    end      
  end
  
  def first_in_post?
    !post or post.new_record? or post.comments.order('created_at asc').first.id == self.id
  end
  
  after_create do
    post.update_attribute(:updated_at, Time.now)
  end
  
  def email_subject
    s = ''
    if commentable.respond_to?(:group)
      s << '['
      s << commentable.group.name
      if commentable.respond_to?(:team)
        s << '/'
        s << commentable.team.name
      end
      s << '] '
    end
    if subject
      if first_in_post?
        s << subject
      else
        s << "Re: #{subject}"
      end
    else
      s << Nokogiri::HTML(description).text
    end
  end
  
  after_create :send_comment
  def send_comment
    if ENV['SMTP_ADDRESS']
      comment = self
      bcc = comment.post.emails
      
      if bcc.length > 0
        mail = Mail.new
        mail.bcc = bcc
        mail.from = "Autopo <#{comment.post_id}@#{ENV['MAILGUN_DOMAIN']}>"
        mail.subject = comment.email_subject
            
        content = ERB.new(File.read(Padrino.root('app/views/emails/comment.erb'))).result(binding)
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
        end
        mail.html_part = html_part
      
        mail.deliver
      end
    end    
  end
  handle_asynchronously :send_comment  
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit}
  end

  def self.admin_fields
    {
      :subject => :text,
      :body => :text_area,
      :file => :file,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :post_id => :lookup
    }
  end
    
end
