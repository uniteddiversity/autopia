class LocalGroup
  include Mongoid::Document
  include Mongoid::Timestamps  
  include Geocoder::Model::Mongoid  
  extend Dragonfly::Model
  
  field :name, :type => String
  field :location, :type => String
  field :coordinates, :type => Array
  field :radius, :type => Integer, :default => 25
  field :image_uid, :type => String    
  
  validates_presence_of :name 
  
  has_many :events, :dependent => :nullify
  has_many :local_groupships, :dependent => :destroy
  has_many :pmails, :as => :mailable, :dependent => :destroy
  
  belongs_to :organisation
  belongs_to :account        
  
  dragonfly_accessor :image    
  
  def subscribers
    subscribed_members
  end  
  
  def members
    Account.where(:id.in => local_groupships.pluck(:account_id))
  end
  
  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy    
  
#  def members
#    Account.where(:coordinates => { "$geoWithin" => { "$centerSphere" => [coordinates, radius / 3963.1676 ]}})
#  end  
  
  def subscribed_members
    Account.where(:id.in => local_groupships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
  
  def unsubscribed_members
    Account.where(:id.in => local_groupships.where(:unsubscribed => true).pluck(:account_id))
  end  
  
  def admins
    Account.where(:id.in => local_groupships.where(:admin => true).pluck(:account_id))
  end  
  
  # Geocoder
  geocoded_by :location
  def lat
    coordinates[1] if coordinates
  end
  def lng
    coordinates[0] if coordinates
  end
  after_validation do
    geocode || (self.coordinates = nil)
  end   

  def self.marker_color
    'red'
  end  
      
  def self.admin_fields
    {
      :name => :text,
      :location => :text,
      :radius => :number
    }
  end
         
end
