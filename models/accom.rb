class Accom
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String  
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  
  belongs_to :group  
  validates_presence_of :name, :cost, :capacity, :group
  
  has_many :accomships, :dependent => :destroy
  
  def members
    Account.where(:id.in => accomship.pluck(:account_id))
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :capacity => :number,
      :cost => :number,
      :group_id => :lookup
    }
  end
  
  def cost_per_person
    if accomships.count > 0
      (cost.to_f / accomships.count).round
    end
  end
  
  def full?
    accomships.count == capacity
  end
    
end
