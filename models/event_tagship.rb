class EventTagship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :event
  belongs_to :event_tag
    
  validates_uniqueness_of :event_tag, :scope => :event

  def self.admin_fields
    {
      :event_id => :lookup,
      :event_tag_id => :lookup,
    }
  end  
  
  def event_tag_name
    event_tag.name
  end
  
end
