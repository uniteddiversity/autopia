class Rota
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
 
  belongs_to :group  
  validates_presence_of  :group
  
  has_many :roles, :dependent => :destroy
  has_many :rslots, :dependent => :destroy
  has_many :shifts, :dependent => :destroy
   
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup,
      :roles => :collection,
      :rslots => :collection,
      :shifts => :collection
    }
  end
    
end
