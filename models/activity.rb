class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :name, :type => String
  field :email, :type => String
  field :website, :type => String
  field :image_uid, :type => String    
#  field :vat_category, :type => String
  
  has_many :events, :dependent => :nullify
  has_many :activityships, :dependent => :destroy
#  has_many :pmails, :dependent => :nullify

  belongs_to :organisation
  belongs_to :account
  
  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy    
  
  has_many :pmails, :as => :mailable, :dependent => :destroy
  
  def event_feedbacks
    EventFeedback.where(:event_id.in => events.pluck(:id))
  end
  
  def average_rating
    ratings = event_feedbacks.where(:rating.ne => nil).pluck(:rating)
    if ratings.length > 0
      ratings = ratings.map(&:to_i)
      (ratings.inject(:+).to_f / ratings.length).round(1)
    end
  end  
  
  dragonfly_accessor :image    
  
  validates_presence_of :name
      
  def self.admin_fields
    {
      :name => :text,
      :email => :email,
      :website => :url,
#      :vat_category => :select,
      :image => :image,      
      :events => :collection
    }
  end
  
#  def self.vat_categories
#    ['', 'Taught', 'Performance', 'Participatory']
#  end

  def subscribers
    subscribed_members
  end  
    
  def members
    Account.where(:id.in => activityships.pluck(:account_id))
  end
  
  def subscribed_members
    Account.where(:id.in => activityships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
  
  def unsubscribed_members
    Account.where(:id.in => activityships.where(:unsubscribed => true).pluck(:account_id))
  end  
  
  def admins
    Account.where(:id.in => activityships.where(:admin => true).pluck(:account_id))
  end
  
  def sync_activityships
    events.each { |event|
      event.tickets.each { |ticket|
        activityships.create account: ticket.account
      }
      event.orders.each { |order|
        activityships.create account: order.account
      }      
    }
  end
  handle_asynchronously :sync_activityships
  
  def self.human_attribute_name(attr, options = {})
    {
      email: 'Contact email'
    }[attr.to_sym] || super
  end  
      
end
