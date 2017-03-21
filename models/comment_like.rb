class CommentLike
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account
  belongs_to :comment
  belongs_to :group
  belongs_to :membership
  belongs_to :team
  
  before_validation do
  	self.team = self.comment.team
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
      :team_id => :lookup
    }
  end
    
end
