class EventTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :event_tagships, :dependent => :destroy

  def self.admin_fields
    {
      name: { type: :text, full: true }
    }
  end
     
end
