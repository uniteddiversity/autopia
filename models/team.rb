class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  belongs_to :group
  validates_presence_of :group
  
  has_many :teamships, :dependent => :destroy
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
