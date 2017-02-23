class Shift
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :role
  belongs_to :rslot
  belongs_to :rota
  
  validates_presence_of :role, :rslot, :rota
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => rota.group, :type => 'signed_up_to_a_shift'
  end  
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :role_id => :lookup,
      :rslot_id => :lookup,    
      :rota_id => :lookup      
    }
  end
      
end
