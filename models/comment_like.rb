class CommentLike
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :comment, index: true
  belongs_to :post, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  belongs_to :team, index: true
  
  before_validation do
  	self.post = self.comment.post if self.comment
  	self.team = self.post.team  if self.post
    self.group = self.team.group if self.team
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :group => group, :type => 'liked_a_comment'
    end
  end    

  def self.admin_fields
    {
			:comment_id => :lookup,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :team_id => :lookup,
      :post_id => :lookup
    }
  end
    
end
