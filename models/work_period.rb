class WorkPeriod
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  belongs_to :membership, index: true

  field :start_time, :type => Time
  field :end_time, :type => Time
  field :description, :type => String
  
  validates_presence_of :start_time
  
  before_validation do
    errors.add(:end_time, 'must be after the start time') if start_time && end_time && end_time < start_time
    errors.add(:end_time, 'must not be in the future') if end_time && end_time > Time.now
    errors.add(:description, 'must be present if end time is set') if end_time && !description
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
    
  before_validation do
    self.start_time = Time.now if !self.start_time
  end
  
  def self.admin_fields
    {     
      :start_time => :datetime,
      :end_time => :datetime,
      :description => :text,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup      
    }
  end
  
  def duration
    (end_time or Time.now) - start_time
  end
          
end
