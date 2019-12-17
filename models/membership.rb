class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :paid, :type => Integer
  field :desired_threshold, :type => Integer
  field :requested_contribution, :type => Integer
  field :unsubscribed, :type => Boolean
  field :member_of_facebook_group, :type => Boolean
  field :hide_from_sidebar, :type => Boolean
    
  belongs_to :gathering, index: true
  belongs_to :account, class_name: "Account", inverse_of: :memberships, index: true
  belongs_to :added_by, class_name: "Account", inverse_of: :memberships_added, index: true, optional: true
  belongs_to :admin_status_changed_by, class_name: "Account", inverse_of: :memberships_admin_status_changed, index: true, optional: true
  belongs_to :mapplication, index: true, optional: true
  
  validates_uniqueness_of :account, :scope => :gathering
  
  before_validation do
    errors.add(:gathering, 'is full') if self.new_record? and gathering.member_limit and gathering.memberships(true).count >= gathering.member_limit    
    self.desired_threshold = 1 if (self.desired_threshold and self.desired_threshold < 1)
    self.paid = 0 if self.paid.nil?
    self.requested_contribution = 0 if self.requested_contribution.nil?    
  end
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy  
  after_create do
    unless prevent_notifications
      notifications.create! :circle => circle, :type => 'joined_gathering'
    end
    gathering.members.each { |follower|
      Follow.create follower: follower, followee: account, unsubscribed: true
    }
    gathering.members.each { |followee|  
      Follow.create follower: account, followee: followee, unsubscribed: true
    }
    if general = gathering.teams.find_by(name: 'General')
      general.teamships.create! account: account, prevent_notifications: true
    end    
  end
  
  def circle
    gathering
  end
  
  after_create :send_email
  def send_email    
    if ENV['SMTP_ADDRESS']
      mail = Mail.new
      mail.to = account.email
      mail.from = ENV['NOTIFICATION_EMAIL']
      mail.subject = "You're now a member of #{gathering.name}"
      
      account = self.account
      gathering = self.gathering
      
      if !account.sign_ins or account.sign_ins == 0
        action = %Q{<a href="#{ENV['BASE_URI']}/accounts/edit?sign_in_token=#{account.sign_in_token}&slug=#{gathering.slug}">Click here to finish setting up your account and get involved with the co-creation!</a>}
      else
        action = %Q{<a href="#{ENV['BASE_URI']}/a/#{gathering.slug}?sign_in_token=#{account.sign_in_token}">Sign in to get involved with the co-creation!</a>}
      end       
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body "Hi #{account.firstname},<br /><br />You're now a member of #{gathering.name} on Autopia. #{action}<br /><br />Best,<br />The Autopia Team" 
      end
      mail.html_part = html_part
      
      mail.deliver  
    end
  end  
  handle_asynchronously :send_email
   
  after_destroy do
    account.notifications_as_notifiable.create! :circle => gathering, :type => 'left_gathering'
    if mapplication
      mapplication.prevent_notifications = true
      mapplication.destroy
    end
  end
  
  def invitations_extended
    gathering.memberships.where(added_by: account).count
  end
  
  def invitations_remaining
    gathering.invitations_granted - invitations_extended
  end
  
  has_many :verdicts, :dependent => :destroy
  has_many :payments, :dependent => :nullify
  has_many :payment_attempts, :dependent => :nullify
  
  # Timetable
  has_many :tactivities, :dependent => :destroy
  has_many :attendances, :dependent => :destroy
  # Teams
  has_many :teamships, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_reactions, :dependent => :destroy
  # Rotas
  has_many :shifts, :dependent => :destroy
  # Tiers
  has_many :tierships, :dependent => :destroy
  def tiership
    tierships.first
  end
  # Accommodation
  has_many :accomships, :dependent => :destroy 
  def accomship
    accomships.first
  end
  # Transport
  has_many :transportships, :dependent => :destroy
  # Budget
  has_many :spends, :dependent => :destroy
  # Inventory
  has_many :inventory_items, :dependent => :nullify
  
  def calculate_requested_contribution    
    c = 0
    if tiership and !tiership.flagged_for_destroy?
      c += tiership.tier.cost
    end
    if accomship and !accomship.flagged_for_destroy?
      c += accomship.accom.cost_per_person
    end    
    transportships.each { |transportship|
      if !transportship.flagged_for_destroy?
        c += transportship.transport.cost
      end
    }    
    c    
  end
  
  def update_requested_contribution    
    update_attribute(:requested_contribution, calculate_requested_contribution)
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :gathering_id => :lookup,      
      :mapplication_id => :lookup,
      :admin => :check_box,
      :paid => :number,
      :desired_threshold => :number,
      :requested_contribution => :number,
      :unsubscribed => :check_box,
      :hide_from_sidebar => :check_box,
      :member_of_facebook_group => :check_box
    }
  end
  
  def confirmed?    
    !gathering.demand_payment or gathering.disable_stripe or paid > 0 or admin?
  end
      
end