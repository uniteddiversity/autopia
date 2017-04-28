class Space
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :activities, :dependent => :nullify
  
  belongs_to :timetable, index: true  
  belongs_to :group, index: true  
  
  validates_presence_of :o
  
  before_validation do    
    self.group = self.timetable.group if self.timetable
    if !self.o
      max = self.timetable.spaces.pluck(:o).compact.max
      self.o = max ? (max+1) : 0
    end
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
