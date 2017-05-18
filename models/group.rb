class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  dragonfly_accessor :image
  
  def self.enablable
    %w{teams qualities timetables rotas tiers accommodation transport bookings budget}
  end  
  
  field :name, :type => String
  field :slug, :type => String
  field :image_uid, :type => String
  field :intro_for_members, :type => String
  field :application_preamble, :type => String
  field :application_questions, :type => String
  field :anonymise_supporters, :type => Boolean
  field :anonymise_blockers, :type => Boolean
  field :democratic_threshold, :type => Boolean
  field :fixed_threshold, :type => Integer
  field :ask_for_date_of_birth, :type => Boolean
  field :ask_for_gender, :type => Boolean
  field :ask_for_poc, :type => Boolean
  field :featured, :type => Boolean
  field :member_limit, :type => Integer
  field :booking_limit, :type => Integer
  field :scheduling_by_all, :type => Boolean
  field :processed_via_huddl, :type => Integer
  field :balance, :type => Float
  field :paypal_email, :type => String
  field :currency, :type => String
  field :teamup_calendar_url, :type => String
  field :mailgun_route_id, :type => String
  enablable.each { |x|
    field :"enable_#{x}", :type => Boolean
  }
    
  before_validation do
    self.balance = 0 if self.balance.nil?
    self.processed_via_huddl = 0 if self.processed_via_huddl.nil?
  end
  
  after_create do    
    notifications.create! :notifiable => self, :type => 'created_group'    
    memberships.create! account: account, admin: true        
    general = teams.create! name: 'General', account: account, prevent_notifications: true
    general.teamships.create! account: account    
  end
  
  after_create :send_email
  def send_email
   	if ENV['SMTP_ADDRESS']
      mail = Mail.new
      mail.to = ENV['ADMIN_EMAIL']
      mail.from = ENV['BOT_EMAIL']
      mail.subject = "New group: #{name}"
      
      group = self
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{#{group.account.name} (#{group.account.email}) created a new group: <a href="https://#{ENV['DOMAIN']}/h/#{group.slug}">#{group.name}</a>}
      end
      mail.html_part = html_part
      
      mail.deliver
    end
  end
  handle_asynchronously :send_email
    
  def create_route
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    response = mg_client.post('routes', {:description => slug, :expression => "match_recipient('^#{slug}\\+(.*)@#{ENV['MAILGUN_DOMAIN']}$')", :action => "forward('https://#{ENV['DOMAIN']}/h/#{slug}/inbound/\\1')"})
    update_attribute(:mailgun_route_id, JSON.parse(response.body)['route']['id'])    
  end  
  
  def delete_route
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    response = mg_client.delete("routes/#{mailgun_route_id}")
  end
  
  belongs_to :account, index: true
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy  
  has_many :notifications, :dependent => :destroy
  has_many :verdicts, :dependent => :destroy
  has_many :payments, :dependent => :nullify
  
  # Timetable
  has_many :timetables, :dependent => :destroy
  has_many :spaces, :dependent => :destroy
  has_many :tslots, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :attendances, :dependent => :destroy
  # Teams
  has_many :teams, :dependent => :destroy
  has_many :teamships, :dependent => :destroy  
  has_many :posts, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy
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
  # Bookings
  has_many :bookings, :dependent => :destroy
  has_many :booking_lifts, :dependent => :destroy
  # Qualities
  has_many :qualities, :dependent => :destroy
  has_many :cultivations, :dependent => :destroy
  
  def application_questions_a
    q = (application_questions || '').split("\n").map(&:strip) 
    q.empty? ? [] : q
  end  
  
  def members
    Account.where(:id.in => memberships.pluck(:account_id))
  end
  
  def cultivators
    Account.where(:id.in => cultivations.pluck(:account_id))
  end
      
  def admin_emails
    Account.where(:id.in => memberships.where(admin: true).pluck(:account_id)).pluck(:email)
  end
  
  def emails
    Account.where(:id.in => memberships.where(:receive_emails => true).pluck(:account_id)).pluck(:email)
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
        
  def self.admin_fields
    h = {
      :name => :text,
      :slug => :slug,      
      :image => :image,
      :intro_for_members => :wysiwyg,
      :fixed_threshold => :number,
      :member_limit => :number,
      :booking_limit => :number,
      :processed_via_huddl => :number,
      :balance => :number,
      :democratic_threshold => :check_box,
      :application_preamble => :wysiwyg,
      :application_questions => :text_area,
      :anonymise_supporters => :check_box,
      :anonymise_blockers => :check_box,
      :scheduling_by_all => :check_box,
      :ask_for_date_of_birth => :check_box,
      :ask_for_gender => :check_box,
      :ask_for_poc => :check_box,
      :featured => :check_box,
      :paypal_email => :text,
      :currency => :select,
      :teamup_calendar_url => :url,
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
    %w{GBP EUR USD}
  end
  
  def self.currency_symbol(code)
    case code
      when 'GBP'; '£'
      when 'EUR'; '€'
      when 'USD'; '$'
    end    
  end
  
  def currency_symbol
    Group.currency_symbol(currency)
  end
    
  
  def self.new_tips
    {      
      :application_questions => 'One per line',
      :scheduling_by_all => 'By default, only admins can schedule activities',
    }
  end
  
  def self.new_hints
    {
      :currency => 'This cannot be changed, choose wisely',
      :fixed_threshold => 'Automatically accept applications with this number of proposers + supporters (with at least one proposer, and no blockers)'
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :paypal_email => 'PayPal email',
      :scheduling_by_all => 'Allow all members to schedule activities',
      :ask_for_poc => 'Ask whether applicants identify as a person of colour',
      :fixed_threshold => 'Magic number',
      :democratic_threshold => 'Allow all group members to suggest the magic number, and use the median',
      :teamup_calendar_url => 'Teamup calendar URL'
    }[attr.to_sym] || super  
  end   
  
  def self.edit_tips
    self.new_tips
  end  
  
  def self.edit_hints
    self.new_hints
  end    
    
  def threshold
    democratic_threshold ? (median_threshold if democratic_threshold) : fixed_threshold
  end
  
  before_validation do
    if democratic_threshold
      self.fixed_threshold = false
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
    
end
