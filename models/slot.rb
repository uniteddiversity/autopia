class Slot
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  
  belongs_to :rota  
  validates_presence_of :rota
          
  def self.admin_fields
    {
      :name => :text,
      :rota_id => :lookup,
    }
  end
    
end
