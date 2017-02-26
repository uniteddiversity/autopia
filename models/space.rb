class Space
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  
  has_many :activities, :dependent => :nullify
  
  belongs_to :group, index: true  
  validates_presence_of :group
        
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup
    }
  end
    
end
