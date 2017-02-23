class Tier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :cost, :type => Integer
  
  belongs_to :group
  validates_presence_of :name, :cost, :group
    
  has_many :tierships, :dependent => :destroy
  
  def members
    Account.where(:id.in => tierships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,      
      :group_id => :lookup,
      :tierships => :collection,
    }
  end
    
end
