class Vote
  include Mongoid::Document
  include Mongoid::Timestamps
 
  belongs_to :option, index: true
  belongs_to :account, index: true
  
  validates_uniqueness_of :account, :scope => :option
  
  def self.admin_fields
    {
      :option_id => :lookup,
      :account_id => :lookup
    }
  end
    
end
