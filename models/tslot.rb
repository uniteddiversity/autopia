class Tslot
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String
  field :o, :type => Integer
  
  has_many :tactivities, :dependent => :nullify
  
  belongs_to :timetable, index: true  
  belongs_to :gathering, index: true  
  
  validates_presence_of :name, :o
  
  before_validation do
    self.gathering = self.timetable.gathering if self.timetable
    if !self.o
      max = self.timetable.tslots.pluck(:o).compact.max
      self.o = max ? (max+1) : 0
    end    
  end
          
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :timetable_id => :lookup,
      :gathering_id => :lookup
    }
  end
    
end
