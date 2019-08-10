class Mapplication
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :status, :type => String
  field :answers, :type => Array  

  belongs_to :gathering, index: true
  belongs_to :account, class_name: "Account", inverse_of: :mapplications, index: true
  belongs_to :processed_by, class_name: "Account", inverse_of: :mapplications_processed, index: true, optional: true
  
  has_many :verdicts, :dependent => :destroy
  # has_one :membership, :dependent => :destroy
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy   
  
  def subscribers
    gathering.subscribers.where(:id.in => (verdicts.pluck(:account_id) + gathering.admins.pluck(:id)))
  end  
  
  validates_presence_of :status
  validates_uniqueness_of :account, :scope => :gathering  
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => gathering, :type => 'applied'
  end 
    
  after_destroy do
    unless prevent_notifications
      account.notifications_as_notifiable.create! :circle => gathering, :type => 'mapplication_removed'
    end
  end  
      
  def self.pending
    where(status: 'pending')
  end
  
  def self.paused
    where(status: 'paused')
  end  
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end
  
  def acceptable?
    status == 'pending' and (!gathering.member_limit or (gathering.memberships.count < gathering.member_limit)) and verdicts.proposers.count > 0
  end
  
  def meets_threshold
    gathering.threshold and (verdicts.proposers.count + (gathering.enable_supporters ? verdicts.supporters.count : 0)) >= gathering.threshold
  end
  
  def accept
    mapplication = self    
    account = mapplication.account
    gathering = mapplication.gathering    
    update_attribute(:status, 'accepted')
    gathering.memberships.create! account: account, mapplication: mapplication
  end
        
  def self.admin_fields
    {
      :summary => {:type => :text, :index => false, :edit => false},
      :account_id => :lookup,
      :gathering_id => :lookup,
      :verdicts => :collection,
      :status => :select,
      :answers => :text_area
    }
  end
  
  def name
    "#{account.name}'s application"
  end
    
  def summary
    "#{self.account.name} - #{self.gathering.name}"
  end
    
  def self.statuses
    ['pending', 'accepted', 'paused']
  end 
  
  def label
    case status
    when 'pending'; 'primary';
    when 'accepted'; 'success';
    when 'paused'; 'warning'
    end
  end

end
