class Tslot
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :activities, :dependent => :nullify
  
  belongs_to :timetable, index: true  
  belongs_to :group, index: true  
  
  before_validation do
    self.group = self.timetable.group if self.timetable
  end
          
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :timetable_id => :lookup,
      :group_id => :lookup
    }
  end
    
end
