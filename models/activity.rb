class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :name, :type => String
  field :slug, :type => String
  field :email, :type => String
  field :website, :type => String
  field :image_uid, :type => String    
#  field :vat_category, :type => String
  
  has_many :activity_facilitations, :dependent => :destroy
  has_many :events, :dependent => :nullify
  has_many :activityships, :dependent => :destroy
#  has_many :pmails, :dependent => :nullify

  belongs_to :promoter
  belongs_to :account
  
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
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
      
  def self.admin_fields
    {
      :name => :text,
      :slug => :slug,
      :email => :email,
      :website => :url,
#      :vat_category => :select,
      :image => :image,      
      :events => :collection,
      :activity_facilitations => :collection
    }
  end
  
#  def self.vat_categories
#    ['', 'Taught', 'Performance', 'Participatory']
#  end
    
  def members
    Account.where(:id.in => activityships.pluck(:account_id))
  end
  
  def subscribed_members
    Account.where(:id.in => activityships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
  
  def unsubscribed_members
    Account.where(:id.in => activityships.where(:unsubscribed => true).pluck(:account_id))
  end  
  
  def activity_facilitators
    Account.where(:id.in => activity_facilitations.pluck(:account_id))
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
      
end
