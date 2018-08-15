class CommentLike
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :comment, index: true
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true
  
  before_validation do
  	self.post = self.comment.post if self.comment
  	self.commentable = self.post.commentable  if self.post
  end    
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account and commentable.respond_to?(:group)
      notifications.create! :group => commentable.group, :type => 'liked_a_comment'
    end
  end    
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit}
  end   

  def self.admin_fields
    {
			:comment_id => :lookup,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :post_id => :lookup
    }
  end
    
end
