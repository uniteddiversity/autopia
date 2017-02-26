class BookingLift
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :group, index: true
  
  field :date, :type => Date
  
  validates_presence_of :group, :date
  validates_uniqueness_of :date, :scope => :group
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :date => :date
    }
  end
    
end
