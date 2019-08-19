class Waitship
  include Mongoid::Document
  include Mongoid::Timestamps
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :event_id => :lookup
    }
  end  

  belongs_to :account
  belongs_to :event
  
  validates_uniqueness_of :account, :scope => :event
      
end
