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
    errors.add(:account, 'is at the booking limit') if membership.booking_limit and membership.bookings.count >= membership.booking_limit
    errors.add(:group, 'is at the booking limit for this date') if group.booking_limit and !group.booking_lifts.find_by(date: date) and group.bookings.where(date: date).count >= group.booking_limit
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :date => :date
    }
  end
  
  def self.json(period_start, period_end)   
    bookings = self
    JSON.pretty_generate (period_start..period_end).map { |date|
      c = bookings.where(date: date).count      
      {
        :title => c == 1 ? "#{c} person" : "#{c} people",
        :start => date.iso8601,
        :end => date.iso8601, 
        :allDay => true,
        :className => c == 0 ? 'no-bookings' : 'some-bookings'         
      }      
    }
  end  
    
end
