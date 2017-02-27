class Space
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :activities, :dependent => :nullify
  
  belongs_to :group, index: true  
  validates_presence_of :group
        
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :group_id => :lookup
    }
  end
    
end
