class Booking
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  field :date, :type => Date
  
  validates_presence_of :date
  validates_uniqueness_of :account, :scope => [:group, :date]
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'booked'
  end    
  
  def membership
    group.memberships.find_by(account: account)
  end
  
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
    errors.add(:account, 'is at the booking limit') if membership.booking_limit and membership.bookings.count >= membership.booking_limit
    errors.add(:group, 'is at the booking limit for this date') if group.booking_limit and !group.booking_lifts.find_by(date: date) and group.bookings.where(date: date).count >= group.booking_limit
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
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
