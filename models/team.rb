class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :intro, :type => String
  field :budget, :type => Integer
    
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name, :gathering
  
  has_many :teamships, :dependent => :destroy
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy
  
  has_many :spends, :dependent => :nullify
  has_many :inventory_items, :dependent => :nullify
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    unless prevent_notifications
      notifications.create! :circle => circle, :type => 'created_team'
    end
  end      
  
  def circle
    gathering
  end
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
  def subscribers
    gathering.subscribers.where(:id.in => teamships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
    
  def spent
    spends.pluck(:amount).sum
  end
        
  def self.admin_fields
    {
      :name => :text,
      :intro => :wysiwyg,
      :gathering_id => :lookup,
      :account_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
