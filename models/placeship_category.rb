class PlaceshipCategory
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  
  belongs_to :account, index: true
  has_many :placeships, :dependent => :nullify
  
  validates_presence_of :name
  
  def self.admin_fields
    {
      :name => :text,
      :account_id => :lookup
    }
  end
    
end
