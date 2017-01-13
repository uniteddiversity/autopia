class Verdict
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String 
  
  belongs_to :account
  belongs_to :mapplication
  
  validates_presence_of :account, :mapplication, :type
  validates_uniqueness_of :account, :scope => :mapplication
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :mapplication_id => :lookup,
      :type => :select,
    }
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
