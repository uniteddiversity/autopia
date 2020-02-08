class Optionship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :option, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  
  validates_uniqueness_of :account, :scope => :option
  
  before_validation do
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
    errors.add(:option, 'is full') if option and option.capacity and option.optionships.count == option.capacity
  end  
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :option_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  after_save do option.optionships.each { |optionship| optionship.membership.update_requested_contribution } end
  after_destroy do option.optionships.each { |optionship| optionship.membership.try(:update_requested_contribution) } end
      
end
