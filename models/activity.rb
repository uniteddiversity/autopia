class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :name, :type => String
  field :email, :type => String
  field :website, :type => String
  field :image_uid, :type => String    
  #  field :vat_category, :type => String
  field :hide_members, :type => Boolean
  field :privacy, :type => String
  field :application_questions, :type => String
  
  has_many :events, :dependent => :nullify
  has_many :activityships, :dependent => :destroy
  has_many :activity_applications, :dependent => :destroy
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
  
  def application_questions_a
    q = (application_questions || '').split("\n").map(&:strip).reject { |l| l.blank? }
    q.empty? ? [] : q
  end   
      
  def self.admin_fields
    {
      :name => :text,
      :email => :email,
      :website => :url,
      #      :vat_category => :select,
      :image => :image,      
      :events => :collection,
      :hide_members => :check_box,
      :privacy => :select,
      :application_questions => :text_area
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
    if privacy == 'open'
      events.each { |event|
        event.tickets.each { |ticket|
          activityships.create account: ticket.account
        }
        event.orders.each { |order|
          activityships.create account: order.account
        }      
      }
    end
  end
  handle_asynchronously :sync_activityships
  
  def self.privacies
    {'Anyone can join' => 'open', 'People must apply to join' => 'closed'}
  end  
  
  def self.human_attribute_name(attr, options = {})
    {
      email: 'Contact email'
    }[attr.to_sym] || super
  end  
      
end
