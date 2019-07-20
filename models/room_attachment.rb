class RoomAttachment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
 
  field :image_uid, :type => String
  
  dragonfly_accessor :image do  
    after_assign do |attachment|
      attachment.convert! '-auto-orient'
    end  
  end
  before_validation do
    if self.image
      begin
        self.image.format
      rescue        
        errors.add(:image, 'must be an image')
      end
    end
  end
  
  belongs_to :room, index: true  
  belongs_to :account, index: true  

  validates_presence_of :image
          
  def self.admin_fields
    {     
      :image => :image,
      :room_id => :lookup
    }
  end
    
end
