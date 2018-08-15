class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :account, index: true
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true

  field :body, :type => String 
  field :title, :type => String
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
  
  def first_in_post?
    !post or post.new_record? or post.comments.order('created_at asc').first.id == self.id
  end
  
  after_create do
    post.update_attribute(:updated_at, Time.now)
  end
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit}
  end

  def self.admin_fields
    {
      :body => :text_area,
      :title => :text,
      :file => :file,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :post_id => :lookup
    }
  end
    
end
