class ActivityFacilitation
  include Mongoid::Document
  include Mongoid::Timestamps
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :activity_id => :lookup
    }
  end  

  belongs_to :account
  belongs_to :activity
  
  validates_uniqueness_of :account, :scope => :activity
    
end
