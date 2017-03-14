class Quality
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
    
  field :name, :type => String
  field :link, :type => String
  field :image_uid, :type => String
  
  dragonfly_accessor :image
 
  belongs_to :group, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :description, :group
  
  has_many :cultivations, :dependent => :destroy
     
  def self.admin_fields
    {
      :name => :text,
      :link => :url,
      :image => :image,
      :group_id => :lookup,
      :account_id => :lookup,
      :cultivations => :collection
    }
  end
    
end
