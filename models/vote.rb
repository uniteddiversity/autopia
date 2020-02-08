class Vote
  include Mongoid::Document
  include Mongoid::Timestamps
 
  belongs_to :voption, index: true
  belongs_to :account, index: true
  
  validates_uniqueness_of :account, :scope => :voption
  
  def self.admin_fields
    {
      :voption_id => :lookup,
      :account_id => :lookup
    }
  end
    
end
