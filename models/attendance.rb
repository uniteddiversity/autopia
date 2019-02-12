class Attendance
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :activity, index: true
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  before_validation do
    self.group = self.activity.group if self.activity
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  validates_uniqueness_of :activity, :scope => :account
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    # notifications.create! :circle => activity.group, :type => 'interested_in_activity'
  end      
        
  def self.admin_fields
    {
      :activity_id => :lookup,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
    
end
