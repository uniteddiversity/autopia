class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  belongs_to :team, index: true

  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy 
  
  after_create do
    team.members.each { |account| subscriptions.create account: account }    
  end

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
      :team_id => :lookup,
      :subscriptions => :collection,
      :comments => :collection
    }
  end
  
  def subscribers
    Account.where(:id.in => subscriptions.pluck(:account_id))
  end
  
  def emails
    subscribers.pluck(:email)
  end
    
end
