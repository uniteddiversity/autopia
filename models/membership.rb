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
  
  def proposed_by
    mapplication ? mapplication.verdicts.proposers.map { |verdict| verdict.account } : ([added_by] if added_by)
  end
  
  after_create :send_email
  def send_email          
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
         
    account = self.account
    gathering = self.gathering
    content = ERB.new(File.read(Padrino.root('app/views/emails/gathering_welcome.erb'))).result(binding)
    batch_message.from ENV['NOTIFICATION_EMAIL']
    batch_message.subject "You're now a member of #{gathering.name}"
    batch_message.body_html ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
                
    [account].each { |account|
      batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id})
    }
        
    batch_message.finalize
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
  # Options
  has_many :optionships, :dependent => :destroy  
  # Budget
  has_many :spends, :dependent => :destroy
  # Inventory
  has_many :inventory_items, :dependent => :nullify
  
  def calculate_requested_contribution    
    c = 0 
    optionships.each { |optionship|
      if !optionship.flagged_for_destroy?
        c += optionship.option.cost_per_person
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
    !gathering.demand_payment or paid > 0 or admin?
  end
  
  def self.protected_attributes
    %w[admin]
  end  
  
end