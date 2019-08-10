class Verdict
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String 
  field :reason, :type => String
  
  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  belongs_to :mapplication, index: true
  
  validates_presence_of :type
  validates_uniqueness_of :account, :scope => :mapplication
  
  before_validation do
    self.gathering = self.mapplication.gathering if self.mapplication
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
    
    if type == 'proposer' and gathering and gathering.proposing_delay and (Time.now - mapplication.created_at) < gathering.proposing_delay.hours
      errors.add(:type, 'is restricted by gathering.proposing_delay')
    end
    
    if type == 'proposer' and gathering and gathering.require_reason_proposer and !reason
      errors.add(:type, 'requires a reason')      
    end
    if type == 'supporter' and gathering and gathering.require_reason_supporter and !reason
      errors.add(:type, 'requires a reason')      
    end
  end
            
  def self.admin_fields
    {
      :account_id => :lookup,
      :mapplication_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup,
      :type => :select,
      :reason => :text
    }
  end
  
  after_create do
    if mapplication.acceptable? and mapplication.meets_threshold
      mapplication.accept    
    end    
  end
  
  def ed
    "#{type[0..-2]}d"
  end
  
  def self.types
    %w{proposer supporter}
  end
  
  def self.proposers
    where(type: 'proposer')
  end

  def self.supporters
    where(type: 'supporter')
  end
      
end
