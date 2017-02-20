class Transport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  
  belongs_to :group
  validates_presence_of :name, :cost, :capacity, :group
  
  has_many :transportships, :dependent => :destroy
  
  def members
    Account.where(:id.in => transportships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,      
      :capacity => :number,
      :group_id => :lookup,
      :transportships => :collection,
    }
  end
    
end
