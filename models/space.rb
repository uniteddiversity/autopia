class Space
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  
  belongs_to :group  
  validates_presence_of :group
        
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup
    }
  end
    
end
