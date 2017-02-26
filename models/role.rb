class Role
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  
  has_many :shifts, :dependent => :destroy
  
  belongs_to :rota, index: true
  validates_presence_of :rota
        
  def self.admin_fields
    {
      :name => :text,
      :rota_id => :lookup
    }
  end
    
end
