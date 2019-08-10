class Tiership
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :tier, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
 
  validates_uniqueness_of :account, :scope => :gathering
  
  before_validation do
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
  end    
             
  def self.admin_fields
    {
      :account_id => :lookup,
      :tier_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  after_save do membership.update_requested_contribution end
  after_destroy do membership.try(:update_requested_contribution) end
      
end
