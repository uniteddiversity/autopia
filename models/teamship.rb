class Teamship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :team, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  validates_uniqueness_of :account, :scope => :team
  
  before_validation do
    self.group = self.team.group if self.team
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    unless prevent_notifications
      notifications.create! :group => team.group, :type => 'joined_team'
    end
  end  
  
  def self.admin_fields
    {
      :account_id => :lookup,
      :team_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
    
end
