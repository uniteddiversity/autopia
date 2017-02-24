class Booking
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :group
  
  field :date, :type => Date
  
  validates_presence_of :account, :group, :date
  validates_uniqueness_of :account, :scope => [:group, :date]
  
  def membership
    group.memberships.find_by(account: account)
  end
  
  before_validation do
    errors.add(:account, 'is at the booking limit') if membership.bookings.count == membership.booking_limit
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :date => :date
    }
  end
    
end
