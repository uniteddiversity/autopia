class Feature
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy  
  
  validates_presence_of :name
  validates_uniqueness_of :name
        
  def self.admin_fields
    {
      :name => :text
    }
  end
  
  def subscribers
    Account.where(admin: true)
  end
    
end
