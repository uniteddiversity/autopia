class Rslot
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :shifts, :dependent => :destroy
  
  belongs_to :rota, index: true  
  belongs_to :group, index: true  
  
  validates_presence_of :o
  
  before_validation do
    self.group = self.rota.group if self.rota
    if !self.o
      max = self.rota.rslots.pluck(:o).compact.max
      self.o = max ? (max+1) : 0
    end    
  end  
          
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :rota_id => :lookup,
      :group_id => :lookup
    }
  end
    
end
