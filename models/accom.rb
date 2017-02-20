class Accom
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :description, :type => String
  field :cost, :type => Integer
  
  belongs_to :group  
  validates_presence_of :name, :description, :cost, :group
  
  has_many :accomships, :dependent => :destroy
  
  def members
    Account.where(:id.in => accomship.pluck(:account_id))
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :cost => :number,
      :group_id => :lookup
    }
  end
  
  def cost_per_person
    if accomships.count > 0
      (cost.to_f / accomships.count).round
    end
  end
    
end
