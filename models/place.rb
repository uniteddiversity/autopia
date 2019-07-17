class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model
  
  field :name, :type => String  
  field :location, :type => String
  field :website, :type => String
  field :coordinates, :type => Array  
  field :image_uid, :type => String
    
  validates_presence_of :name, :location
  
  belongs_to :account, index: true, optional: true
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy  

  def subscribers
    [account]
  end
      
  dragonfly_accessor :image 
  before_validation do
    if self.image
      begin
        self.image.format
      rescue        
        errors.add(:image, 'must be an image')
      end
    end
  end  
  
  # Geocoder
  geocoded_by :location  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end    
  
  def self.marker_color
    'red'
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :website => :url        
    }
  end
    
end
