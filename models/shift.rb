class Shift
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :role
  belongs_to :rslot
  belongs_to :rota
  
  validates_presence_of :account, :role, :rslot, :rota
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :role_id => :lookup,
      :rslot_id => :lookup,    
      :rota_id => :lookup      
    }
  end
    
end
