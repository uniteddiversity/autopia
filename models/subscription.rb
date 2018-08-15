class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :account, index: true
  belongs_to :post, index: true
  
  belongs_to :commentable, polymorphic: true, index: true
  
  validates_presence_of :post, :account, :commentable
  validates_uniqueness_of :account, :scope => :post

  before_validation do
  	self.commentable = self.post.commentable if self.post
  end    
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit}
  end    

  def self.admin_fields
    {
      :id => {:type => :text, :edit => false},
      :post_id => :lookup,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select
    }
  end
    
end
