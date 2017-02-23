class Verdict
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String 
  field :reason, :type => String
  
  belongs_to :account
  belongs_to :mapplication
  
  validates_presence_of :account, :mapplication, :type
  validates_uniqueness_of :account, :scope => :mapplication
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if type == 'proposer' or (type == 'supporter' and !mapplication.group.anonymous_supporters) or (type == 'blocker' and !mapplication.group.anonymous_blockers)
      notifications.create! :group => mapplication.group, :type => 'gave_verdict'
    end
  end   
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :mapplication_id => :lookup,      
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
