class Role
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :shifts, :dependent => :destroy
  
  belongs_to :rota, index: true
  belongs_to :gathering, index: true
  
  validates_presence_of :name, :o
  
  before_validation do
    self.gathering = self.rota.gathering if self.rota
    if !self.o
      max = self.rota.roles.pluck(:o).compact.max
      self.o = max ? (max+1) : 0
    end    
  end      
        
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :rota_id => :lookup,
      :gathering_id => :lookup
    }
  end
    
end
