class Attendance
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :activity, index: true
  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  
  before_validation do
    self.gathering = self.activity.gathering if self.activity
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
  end  
  
  validates_uniqueness_of :activity, :scope => :account
            
  def self.admin_fields
    {
      :activity_id => :lookup,
      :account_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup
    }
  end
    
end
