class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account
  belongs_to :group
  belongs_to :membership
  belongs_to :team

  field :body, :type => String 
  
  has_many :comment_likes, :dependent => :destroy

  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :group => group, :type => 'commented'
    end
  end  
  
  before_validation do
    self.group = self.team.group if self.team
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    

  def self.admin_fields
    {
      :body => :wysiwyg,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :team_id => :lookup
    }
  end
    
end
