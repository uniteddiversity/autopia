class Rslot
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :shifts, :dependent => :destroy
  
  belongs_to :rota, index: true  
  belongs_to :group, index: true  
  validates_presence_of :rota, :group
  
  before_validation do
    self.group = self.rota.group if self.rota
  end  
          
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :rota_id => :lookup
    }
  end
    
end
