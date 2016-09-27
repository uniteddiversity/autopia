class Shift
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :rota_role
  belongs_to :slot
  belongs_to :rota
  
  validates_presence_of :account, :rota_role, :slot, :rota
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :rota_role_id => :lookup,
      :slot_id => :lookup,    
      :rota_id => :lookup      
    }
  end
    
end
