class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  belongs_to :gathering
  validates_presence_of :gathering
  
  has_many :teamships, :dependent => :destroy
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :gathering_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
