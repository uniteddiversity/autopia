class Space
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
 
  field :name, :type => String
  field :o, :type => Integer
  field :image_uid, :type => String
  
  dragonfly_accessor :image  
  
  has_many :activities, :dependent => :nullify
  
  belongs_to :timetable, index: true  
  belongs_to :group, index: true  
  
  validates_presence_of :name, :o
  
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
      :image => :image,
      :o => :number,
      :timetable_id => :lookup,
      :group_id => :lookup
    }
  end
    
end
