class Accomship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :accom, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  
  validates_uniqueness_of :account, :scope => :accom
  
  before_validation do
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
    errors.add(:accom, 'is full') if accom and accom.capacity and accom.accomships.count == accom.capacity
  end  
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :accom_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  after_save do accom.accomships.each { |accomship| accomship.membership.update_requested_contribution } end
  after_destroy do accom.accomships.each { |accomship| accomship.membership.try(:update_requested_contribution) } end
      
end
