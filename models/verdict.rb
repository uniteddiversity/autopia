class Verdict
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String 
  field :reason, :type => String
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  belongs_to :mapplication, index: true
  
  validates_presence_of :type
  validates_uniqueness_of :account, :scope => :mapplication
  
  before_validation do
    self.group = self.mapplication.group if self.mapplication
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
    
    if type == 'proposer' and group and group.proposing_delay and (Time.now - mapplication.created_at) < group.proposing_delay.hours
      errors.add(:type, 'is restricted by group.proposing_delay')
    end
  end
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if type == 'proposer' or (type == 'supporter' and !mapplication.group.anonymise_supporters) or (type == 'blocker' and !mapplication.group.anonymise_blockers)
      notifications.create! :group => mapplication.group, :type => 'gave_verdict'
    end
  end   
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :mapplication_id => :lookup,
      :group_id => :lookup,
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
    %w{proposer supporter blocker}
  end
  
  def self.proposers
    where(type: 'proposer')
  end

  def self.supporters
    where(type: 'supporter')
  end
  
  def self.blockers
    where(type: 'blocker')
  end
    
end
