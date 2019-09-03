class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :account, index: true, inverse_of: :comments_as_creator
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true
 
  field :body, :type => String 
  field :file_uid, :type => String
  
  def self.commentable_types
    %w{Team Activity Mapplication Account Habit Feature Place Photo}
  end    
  
  dragonfly_accessor :file  
      
  has_many :comment_reactions, :dependent => :destroy
  has_many :options, :dependent => :destroy
  has_many :read_receipts, :dependent => :destroy
  has_many :photos, as: :photoable, dependent: :destroy  
  
  after_create do
    post.subscriptions.create account: account
    body.scan(/\[@[\w\s'-\.]+\]\(@(\w+)\)/) { |match|
      post.subscriptions.create account: Account.find_by(username: match[0])
    } if body
  end
  
  def body_with_additions
    if body
      b = body
      b = b.gsub("\n","<br />")
      b = b.gsub(/\[@([\w\s'-\.]+)\]\(@(\w+)\)/,'<a href="'+ENV['BASE_URI']+'/u/\2">\1</a>')
      b
    end
  end

  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'commented'
  end
  
  def circle
    if %w{Team Activity Mapplication}.include?(commentable_type)
      commentable.gathering
    elsif %w{Account Place}.include?(commentable_type)
      commentable
    elsif %w{Habit}.include?(commentable_type)
      commentable.account
    elsif %w{Photo}.include?(commentable_type)
      commentable.photoable.circle
    end
  end
  
  def subscribers
    post.subscribers
  end
  
  def name
    post.subject
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
        "<strong>#{account.name}</strong> started a thread"                  
      else
        "<strong>#{account.name}</strong> replied"                  
      end
    end      
  end
  
  def first_in_post?
    !post or post.new_record? or post.comments.order('created_at asc').first.id == self.id
  end
  
  def first_in_post
    post.comments.order('created_at asc').first
  end
  
  after_create do
    post.update_attribute(:updated_at, Time.now)
  end
  
  def email_subject
    s = ''
    if commentable.is_a?(Feature)
      feature = commentable
      s << "[Features/#{feature.name}] " 
    elsif commentable.is_a?(Place)
      place = commentable
      s << "[Places/#{place.name}] "      
    elsif commentable.is_a?(Habit)
      habit = commentable
      s << "[#{habit.account.name}/#{habit.name}] "
    elsif commentable.is_a?(Photo)
      photo = commentable
      s << "[Photos/#{photo.photoable.name}] "      
    elsif commentable.is_a?(Account)
      account = commentable
      s << "[#{account.name}] "
    elsif commentable.respond_to?(:gathering)
      s << '['
      s << commentable.gathering.name
      if commentable.is_a?(Team)
        team = commentable
        s << '/'
        s << team.name
      elsif commentable.is_a?(Activity)
        activity = commentable
        s << '/'
        s << activity.timetable.name
        s << '/'
        s << activity.name
      elsif commentable.is_a?(Mapplication)
        mapplication = commentable
        s << '/'
        s << "#{mapplication.account.name}'s application"
      end      
      s << '] '
    end
    if post.subject
      if first_in_post?
        s << post.subject
      else
        s << "Re: #{post.subject}"
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
        mail.from = "Autopia <#{comment.post_id}@#{ENV['MAILGUN_DOMAIN']}>"
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
  
  def self.admin_fields
    {
      :body => :text_area,
      :file => :file,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :post_id => :lookup
    }
  end
    
end
