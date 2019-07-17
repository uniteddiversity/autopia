class CommentReaction
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String
  
  belongs_to :account, index: true, inverse_of: :comment_reactions_as_creator
  belongs_to :comment, index: true
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true
  
  before_validation do
  	self.post = self.comment.post if self.comment
  	self.commentable = self.post.commentable  if self.post
    self.body = self.body.split(' ').first if self.body
  end    
  
  validates_uniqueness_of :account, :scope => :comment
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      if %w{Team Activity Mapplication}.include?(commentable_type)
        notifications.create! :circle => commentable.group, :type => 'reacted_to_a_comment'
      elsif %w{Account}.include?(commentable_type)
        notifications.create! :circle => commentable, :type => 'reacted_to_a_comment'            
      elsif %w{Habit}.include?(commentable_type)
        notifications.create! :circle => commentable.account, :type => 'reacted_to_a_comment' 
      end
    end
  end
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit Feature Place}
  end   

  def self.admin_fields
    {
      :body => :text,
      :comment_id => :lookup,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :post_id => :lookup
    }
  end
    
end
