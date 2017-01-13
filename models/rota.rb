class Rota
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
 
  belongs_to :group  
  validates_presence_of  :group
  
  has_many :rota_roles, :dependent => :destroy
  has_many :slots, :dependent => :destroy
  has_many :shifts, :dependent => :destroy
   
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup,
      :rota_roles => :collection,
      :slots => :collection,
      :shifts => :collection
    }
  end
    
end
