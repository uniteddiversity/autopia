class Gathering
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  dragonfly_accessor :image
  
  def self.enablable
    %w{teams timetables rotas tiers accommodation transport inventory budget comments_on_gathering_homepage}
  end  
  
  field :name, :type => String
  field :slug, :type => String
  field :location, :type => String
  field :coordinates, :type => Array  
  field :image_uid, :type => String
  field :intro_for_members, :type => String
  field :privacy, :type => String
  field :intro_for_non_members, :type => String
  field :application_questions, :type => String
  field :enable_supporters, :type => Boolean
  field :anonymise_supporters, :type => Boolean
  field :democratic_threshold, :type => Boolean
  field :fixed_threshold, :type => Integer
  field :member_limit, :type => Integer
  field :proposing_delay, :type => Integer
  field :require_reason_proposer, :type => Boolean
  field :require_reason_supporter, :type => Boolean
  field :processed_via_stripe, :type => Integer
  field :balance, :type => Float
  field :paypal_email, :type => String
  field :currency, :type => String
  field :facebook_group_url, :type => String
  field :demand_payment, :type => Boolean
  field :hide_members_on_application_form, :type => Boolean
  field :invitations_granted, :type => Integer
  field :stripe_connect_json, :type => String  
  field :use_main_stripe, :type => Boolean
  enablable.each { |x|
    field :"enable_#{x}", :type => Boolean
  }
  
  include Geocoder::Model::Mongoid
  geocoded_by :location  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end   
    
  def self.privacies
    {'Anyone can join' => 'open', 'People must apply to join' => 'closed', 'Invitation-only' => 'secret'}
  end
      
  def self.marker_color
    'red'
  end    
  
  before_validation do
    self.balance = 0 if self.balance.nil?
    self.invitations_granted = 0 if self.invitations_granted.nil?
    self.processed_via_stripe = 0 if self.processed_via_stripe.nil?
    self.enable_teams = true if self.enable_budget
    self.member_limit = self.memberships.count if self.member_limit and self.member_limit < self.memberships.count
  end
  
  after_create do    
    notifications_as_notifiable.create! :circle => circle, :type => 'created_gathering'    
    memberships.create! account: account, admin: true        
    if enable_teams
      general = teams.create! name: 'General', account: account, prevent_notifications: true
      general.teamships.create! account: account, prevent_notifications: true
    end
  end
  
  def circle
    self
  end
  
  after_create :send_email
  def send_email
   	if ENV['SMTP_ADDRESS']
      mail = Mail.new
      mail.to = ENV['ADMIN_EMAIL']
      mail.from = ENV['BOT_EMAIL']
      mail.subject = "New gathering: #{name}"
      
      gathering = self
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{#{gathering.account.name} (#{gathering.account.email}) created a new gathering: <a href="#{ENV['BASE_URI']}/a/#{gathering.slug}">#{gathering.name}</a>}
      end
      mail.html_part = html_part
      
      mail.deliver
    end
  end
  handle_asynchronously :send_email
      
  belongs_to :account, index: true
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :notifications_as_notifiable, :as => :notifiable, :dependent => :destroy, :class_name => "Notification", :inverse_of => :notifiable
  has_many :notifications_as_circle, :as => :circle, :dependent => :destroy, :class_name => "Notification", :inverse_of => :circle
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy    
  has_many :verdicts, :dependent => :destroy
  has_many :payments, :dependent => :nullify
  has_many :payment_attempts, :dependent => :nullify
  has_many :withdrawals, :dependent => :nullify
  
  # Timetable
  has_many :timetables, :dependent => :destroy
  has_many :spaces, :dependent => :destroy
  has_many :tslots, :dependent => :destroy
  has_many :tactivities, :dependent => :destroy
  has_many :attendances, :dependent => :destroy
  # Teams
  has_many :teams, :dependent => :destroy
  has_many :teamships, :dependent => :destroy  
  # Rotas
  has_many :rotas, :dependent => :destroy
  has_many :roles, :dependent => :destroy
  has_many :rslots, :dependent => :destroy
  has_many :shifts, :dependent => :destroy
  # Tiers
  has_many :tiers, :dependent => :destroy
  has_many :tierships, :dependent => :destroy
  # Accommodation
  has_many :accoms, :dependent => :destroy
  has_many :accomships, :dependent => :destroy
  # Transport
  has_many :transports, :dependent => :destroy
  has_many :transportships, :dependent => :destroy
  # Budget  
  has_many :spends, :dependent => :destroy
  # Inventory
  has_many :inventory_items, :dependent => :destroy
  # Photos
  has_many :photos, as: :photoable, dependent: :destroy
  
  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy  
  
  def application_questions_a
    q = (application_questions || '').split("\n").map(&:strip).reject { |l| l.blank? }
    q.empty? ? [] : q
  end  
  
  def members
    Account.where(:id.in => memberships.pluck(:account_id))
  end
        
  def admin_emails
    Account.where(:id.in => memberships.where(admin: true).pluck(:account_id)).pluck(:email)
  end
    
  def subscribers
    Account.where(:unsubscribed.ne => true).where(:id.in => memberships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
    
  def vouchers
    enable_supporters ? 'proposers + supporters (with at least one proposer)' : (threshold == 1 ? 'proposer' : 'proposers')
  end
  
  def incomings
    i = 0
    tiers.each { |tier|
      i += tier.cost*tier.tierships.count
    }
    accoms.select { |accom| accom.accomships.count > 0 }.each { |accom|
      i += accom.cost
    }
    transports.each { |transport|
      i += transport.cost*transport.transportships.count
    }
    i
  end
  
  def anonymise_proposers
    false
  end
  
  def enable_proposers
    true
  end
  
  def stripe_user_id
    JSON.parse(stripe_connect_json)['stripe_user_id']
  end  
        
  def self.admin_fields
    h = {
      :name => :text,
      :slug => :slug,     
      :location => :text,
      :image => :image,
      :intro_for_members => :wysiwyg,
      :fixed_threshold => :number,
      :member_limit => :number,
      :proposing_delay => :number,
      :require_reason_proposer => :check_box,
      :require_reason_supporter => :check_box,
      :processed_via_stripe => :number,
      :balance => :number,
      :democratic_threshold => :check_box,
      :privacy => :select,      
      :intro_for_non_members => :wysiwyg,
      :application_questions => :text_area,
      :enable_supporters => :check_box,
      :anonymise_supporters => :check_box,
      :demand_payment => :check_box,      
      :hide_members_on_application_form => :check_box,
      :use_main_stripe => :check_box,
      :paypal_email => :text,
      :stripe_connect_json => :text_area,
      :currency => :select,
      :facebook_group_url => :url,
      :account_id => :lookup,
      :memberships => :collection,
      :mapplications => :collection,
      :spends => :collection,
      :rotas => :collection,
      :teams => :collection
    }
    h.merge(Hash[enablable.map { |x|
          ["enable_#{x}".to_sym, :check_box]
        }])
  end
  
  def self.currencies
    %w{GBP EUR USD SEK DKK}
  end
  
  def self.currency_symbol(code)
    case code
    when 'GBP'; '£'
    when 'EUR'; '€'
    when 'USD'; '$'
    when 'SEK'; 'SEK'
    when 'DKK'; 'DKK'
    end    
  end
  
  def currency_symbol
    Gathering.currency_symbol(currency)
  end
    
  def admins
    Account.where(:id.in => memberships.where(:admin => true).pluck(:account_id))
  end
  
  def self.new_tips
    {      
      :slug => 'Lowercase letters, numbers and dashes only (no spaces)',
      :application_questions => 'One per line'
    }
  end
  
  def self.new_hints
    {
      :slug => %Q{Gathering URL: #{ENV['BASE_URI']}/a/<span class="slug-replace"></span>},
      :currency => 'This cannot be changed, choose wisely',
      :fixed_threshold => 'Automatically accept applications with this number of proposers + supporters (with at least one proposer)',
      :proposing_delay => 'Accept proposers on applications only once the application is this many hours old'
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :intro_for_non_members => 'Intro for non-members',
      :paypal_email => 'PayPal email',     
      :fixed_threshold => 'Magic number',
      :democratic_threshold => 'Allow all gathering members to suggest a magic number, and use the median',
      :facebook_group_url => 'Facebook group URL',
      :require_reason_proposer => 'Proposers must provide a reason',
      :require_reason_supporter => 'Supporters must provide a reason',
      :demand_payment => 'Members must make a payment to access gathering content',
      :hide_members_on_application_form => "Don't show existing members on the application form",
      :invitations_granted => "People may invite this many others"
    }[attr.to_sym] || super  
  end   
  
  def self.edit_tips
    self.new_tips
  end  
  
  def self.edit_hints
    self.new_hints
  end    
    
  def threshold
    democratic_threshold ? median_threshold : fixed_threshold
  end
  
  before_validation do
    if democratic_threshold
      self.fixed_threshold = nil
    end
    true
  end
  
  def median_threshold
    array = memberships.pluck(:desired_threshold).compact
    if array.length > 0
      sorted = array.sort
      len = sorted.length
      ((sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0).round
    end
  end
  
  def radio_scopes
    x = []

    #    if ask_for_date_of_birth
    #      youngest = Account.where(:id.in => memberships.pluck(:account_id)).where(:date_of_birth.ne => nil).order('date_of_birth desc').first
    #      oldest = Account.where(:id.in => memberships.pluck(:account_id)).where(:date_of_birth.ne => nil).order('date_of_birth asc').first
    #      if youngest and oldest
    #        x << [:p, 'all', 'All ages', memberships]
    #        (youngest.age.to_s[0].to_i).upto(oldest.age.to_s[0].to_i) do |p| p = "#{p}0".to_i;
    #          x << [:p, p, "People in their #{p}s", memberships.where(:account_id.in => Account.where(:date_of_birth.lte => (Date.current-p.years)).where(:date_of_birth.gt => (Date.current-(p+10).years)).pluck(:id))]
    #        end
    #      end
    #    end 
    
    x
  end
  
  def check_box_scopes
    y = []
        
    y << [:admin, 'Admins', memberships.where(:admin => true)]
    
    y << [:women, 'Women', memberships.where(:account_id.in => members.where(:gender.in => ['Woman', 'Cis Woman']).pluck(:id))]
    y << [:men, 'Men', memberships.where(:account_id.in => members.where(:gender.in => ['Man', 'Cis Man']).pluck(:id))]
    y << [:other_genders, 'Other genders', memberships.where(:account_id.in => members.where(:gender.nin => ['Woman', 'Cis Woman', 'Man', 'Cis Man', nil]).pluck(:id))]
    y << [:unknown_gender, 'Gender not listed', memberships.where(:account_id.in => members.where(:gender => nil).pluck(:id))]    

    if enable_budget
      y << [:paid_something, 'Paid something', memberships.where(:paid.gt => 0)]
      y << [:paid_nothing, 'Paid nothing', memberships.where(:paid => 0)]  
      y << [:more_to_pay, 'More to pay', memberships.where('this.paid < this.requested_contribution')]
      y << [:no_more_to_pay, 'No more to pay', memberships.where('this.paid == this.requested_contribution')]    
      y << [:overpaid, 'Overpaid', memberships.where('this.paid > this.requested_contribution')]
    end

    if enable_rotas
      y << [:with_shifts, 'With shifts', memberships.where(:account_id.in => shifts.pluck(:account_id))]
      y << [:without_shifts, 'Without shifts', memberships.where(:account_id.nin => shifts.pluck(:account_id))]
    end

    if enable_teams
      y << [:with_teams, 'With teams', memberships.where(:account_id.in => teamships.where(:team_id.nin => teams.where(name: 'General').pluck(:id)).pluck(:account_id))]
      y << [:without_teams, 'Without teams', memberships.where(:account_id.nin => teamships.where(:team_id.nin => teams.where(name: 'General').pluck(:id)).pluck(:account_id))]
    end

    if enable_tiers
      y << [:with_tiers, 'With tier', memberships.where(:account_id.in => tierships.pluck(:account_id))]
      y << [:without_tiers, 'Without tier', memberships.where(:account_id.nin => tierships.pluck(:account_id))]
    end

    if enable_accommodation
      y << [:with_accom, 'With accommodation', memberships.where(:account_id.in => accomships.pluck(:account_id))]
      y << [:without_accom, 'Without accommodation', memberships.where(:account_id.nin => accomships.pluck(:account_id))]
    end

    if facebook_group_url
      y << [:member_of_facebook_group, 'Member of Facebook group', memberships.where(:member_of_facebook_group => true)]
      y << [:not_member_of_facebook_group, 'Not member of Facebook group', memberships.where(:member_of_facebook_group.ne => true)]
    end

    if democratic_threshold
      y << [:threshold, 'Suggesting magic number', memberships.where(:desired_threshold.ne => nil)]
    end

    y    
  end
    
end
