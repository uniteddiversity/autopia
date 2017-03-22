class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account
  belongs_to :group
  belongs_to :membership
  belongs_to :team

  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy

  before_validation do
    self.group = self.team.group if self.team
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    

  def self.admin_fields
    {
      :id => {:type => :text, :edit => false},
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :team_id => :lookup
    }
  end
    
end
