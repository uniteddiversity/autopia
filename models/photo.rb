class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :photoable, polymorphic: true, index: true
  belongs_to :account, index: true    
 
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
  
  validates_presence_of :image
  
  def self.photoables
    %w{Gatheering Room}
  end
          
  def self.admin_fields
    {     
      :image => :image,
      :photoable_id => :text,
      :photoable_type => :select,
    }
  end
    
end
