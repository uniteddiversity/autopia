class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  belongs_to :photoable, polymorphic: true, index: true
  belongs_to :account, index: true    
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy
  
  def self.photoables
    %w{Gathering Room Comment}
  end  
  
  def url
    if photoable.is_a?(Gathering)
      gathering = photoable
      "#{ENV['BASE_URI']}/a/#{gathering.slug}#photo-#{id}"
    elsif photoable.is_a?(Room)
      room = photoable
      "#{ENV['BASE_URI']}/rooms/#{room.id}#photo-#{id}"      
    elsif photoable.is_a?(Comment)
      comment = photoable
      comment.post.url
    end
  end
  
  def subscribers    
    photoable.subscribers
  end  
  
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
            
  def self.admin_fields
    {     
      :image => :image,
      :photoable_id => :text,
      :photoable_type => :select,
    }
  end
    
end
