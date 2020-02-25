class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model
      
  field :name, type: String
  field :name_transliterated, type: String
  field :ps_account_id, type: String
  field :updated_profile, type: Boolean
  field :email, type: String
  field :phone, type: String
  field :telegram_username, type: String
  field :username, type: String
  field :website, type: String
  field :gender, type: String
  field :sexuality, type: String
  field :date_of_birth, type: Date
  field :dietary_requirements, type: String
  field :admin, type: Boolean
  field :time_zone, type: String
  field :crypted_password, type: String
  field :picture_uid, type: String
  field :sign_ins, type: Integer
  field :sign_in_token, type: String
  field :unsubscribed, type: Boolean
  field :unsubscribed_habit_completion_likes, type: Boolean
  field :unsubscribed_messages, type: Boolean
  field :unsubscribed_feedback, type: Boolean
  field :facebook_name, type: String
  field :facebook_profile_url, type: String
  field :not_on_facebook, type: Boolean
  field :last_active, type: Time
  field :last_checked_notifications, type: Time
  field :location, type: String
  field :coordinates, type: Array
  field :open_to_hookups, type: Boolean
  field :open_to_new_friends, type: Boolean
  field :open_to_short_term_dating, type: Boolean
  field :open_to_long_term_dating, type: Boolean
  field :open_to_open_relating, type: Boolean
  field :default_currency, type: String
  field :stripe_connect_json, type: String  
  
  def private?
    !public?
  end
  
  def public?
    !ps_account_id or sign_ins > 0
  end

  def self.open_to
    %w[new_friends hookups short_term_dating long_term_dating open_relating]
  end

  def open_to
    Account.open_to.select { |x| send("open_to_#{x}") }
  end

  def self.protected_attributes
    %w[admin]
  end

  before_validation do
    if !username && (name || email)      
      u = name.parameterize.underscore if name
      if u.blank? && email
        u = email.split('@').first.parameterize.underscore
      end
      if !Account.find_by(username: u)
        self.username = u
      else
        n = 1
        while Account.find_by(username: "#{u}#{n}")
          n += 1
        end
        self.username ="#{u}#{n}"
      end
    end
    self.sign_in_token = SecureRandom.uuid unless sign_in_token
    self.name = name.strip if name
    self.name_transliterated = I18n.transliterate(name) if name
    self.username = username.downcase if username
    self.email = email.downcase.strip if email
    self.sign_ins = 0 if !sign_ins
    if self.postcode
      self.location = "#{self.postcode}, UK"
    end
    
    errors.add(:name, 'must not contain an @') if name && name.include?('@')
    errors.add(:email, 'must not contain commas') if self.email and self.email.include?(',')
    errors.add(:email, 'must not contain semicolons') if self.email and self.email.include?(';')
                    
    if !self.password and !self.crypted_password
      self.password = Account.generate_password(8) # if there's no password, just set one
    end    

    errors.add(:facebook_profile_url, 'must contain facebook.com') if facebook_profile_url && !facebook_profile_url.include?('facebook.com')
    self.facebook_profile_url = "https://#{facebook_profile_url}" if facebook_profile_url && facebook_profile_url !~ %r{\Ahttps?://}
    self.facebook_profile_url = facebook_profile_url.gsub('m.facebook.com', 'facebook.com') if facebook_profile_url

    errors.add(:date_of_birth, 'is invalid') if age && age <= 0
  end

  # Geocoder
  geocoded_by :location
  def lat
    coordinates[1] if coordinates
  end

  def lng
    coordinates[0] if coordinates
  end
  after_validation do
    geocode || (self.coordinates = nil)
  end

  def self.marker_color
    'green'
  end

  def network
    Account.where(:id.in => follows_as_follower.pluck(:followee_id))
  end

  def gatheringies
    Account.where(:id.in => Membership.where(:gathering_id.in => memberships.pluck(:gathering_id)).pluck(:account_id))
  end

  def subscribers
    Account.where(:id.in => [id] + follows_as_followee.where(:unsubscribed.ne => true).pluck(:follower_id))
  end

  def network_notifications
    Notification.or(
      { :circle_type => 'Gathering', :circle_id.in => memberships.pluck(:gathering_id) },
      { :circle_type => 'Account', :circle_id.in => [id] + network.pluck(:id) },
      :circle_type => 'Place', :circle_id.in => places_following.pluck(:id)
    )
  end

  has_many :uploads, dependent: :destroy
  
  has_many :organisations, dependent: :nullify
  has_many :organisationships, dependent: :destroy
  
  has_many :activity_applications, :class_name => "ActivityApplication", :inverse_of => :account, :dependent => :destroy
  has_many :statused_activity_applications, :class_name => "ActivityApplication", :inverse_of => :statused_by, :dependent => :nullify     

  has_many :events, class_name: 'Event', inverse_of: :account, dependent: :destroy
  has_many :events_coordinating, class_name: 'Event', inverse_of: :coordinator, dependent: :nullify
  has_many :events_revenue_sharing, class_name: 'Event', inverse_of: :revenue_sharer, dependent: :nullify
  has_many :event_facilitations, dependent: :destroy
  has_many :waitships, dependent: :destroy
  has_many :event_feedbacks, dependent: :destroy
  has_many :activities, dependent: :nullify
  has_many :activityships, dependent: :destroy
  has_many :local_groups, dependent: :nullify
  has_many :local_groupships, dependent: :destroy  

  has_many :places, dependent: :nullify

  has_many :gatherings, dependent: :nullify

  has_many :mapplications, class_name: 'Mapplication', inverse_of: :account, dependent: :destroy
  has_many :mapplications_processed, class_name: 'Mapplication', inverse_of: :processed_by, dependent: :nullify

  has_many :verdicts, dependent: :destroy

  has_many :memberships, class_name: 'Membership', inverse_of: :account, dependent: :destroy
  has_many :memberships_added, class_name: 'Membership', inverse_of: :added_by, dependent: :nullify
  has_many :memberships_admin_status_changed, class_name: 'Membership', inverse_of: :admin_status_changed_by, dependent: :nullify

  has_many :payments, dependent: :destroy
  has_many :payment_attempts, dependent: :destroy

  # Timetable
  has_many :timetables, dependent: :nullify
  has_many :tactivities, class_name: 'Tactivity', inverse_of: :account, dependent: :destroy
  has_many :tactivities_scheduled, class_name: 'Tactivity', inverse_of: :scheduled_by, dependent: :nullify
  has_many :attendances, dependent: :destroy
  # Teams
  has_many :teams, dependent: :nullify
  has_many :teamships, dependent: :destroy
  has_many :read_receipts, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :votes, dependent: :destroy
  # Rotas
  has_many :rotas, dependent: :nullify
  has_many :shifts, dependent: :destroy
  # Options
  has_many :options, dependent: :nullify
  has_many :optionships, dependent: :destroy    
  # Budget
  has_many :spends, dependent: :destroy
  # Inventory
  has_many :inventory_items_listed, class_name: 'InventoryItem', inverse_of: :account, dependent: :nullify
  has_many :inventory_items_provided, class_name: 'InventoryItem', inverse_of: :responsible, dependent: :nullify
  # Habits
  has_many :habits, dependent: :destroy
  has_many :habit_completions, dependent: :destroy
  has_many :habit_completion_likes, dependent: :destroy
  # Follows
  has_many :follows_as_follower, class_name: 'Follow', inverse_of: :follower, dependent: :destroy
  has_many :follows_as_followee, class_name: 'Follow', inverse_of: :followee, dependent: :destroy
  # Messages
  has_many :messages_as_messenger, class_name: 'Message', inverse_of: :messenger, dependent: :destroy
  has_many :messages_as_messengee, class_name: 'Message', inverse_of: :messengee, dependent: :destroy
  def messages
    Message.or({ messenger: self }, messengee: self)
  end
  # MessageReceipts
  has_many :message_receipts_as_messenger, class_name: 'MessageReceipt', inverse_of: :messenger, dependent: :destroy
  has_many :message_receipts_as_messengee, class_name: 'MessageReceipt', inverse_of: :messengee, dependent: :destroy
  # Placeships
  has_many :placeships, dependent: :destroy
  def places_following
    Place.where(:id.in => placeships.pluck(:place_id))
  end
  has_many :placeship_categories, dependent: :destroy
  # Rooms
  has_many :rooms, dependent: :destroy
  has_many :room_periods, dependent: :destroy
  
  has_many :photos, dependent: :destroy

  has_many :notifications_as_notifiable, as: :notifiable, dependent: :destroy, class_name: 'Notification', inverse_of: :notifiable
  has_many :notifications_as_circle, as: :circle, dependent: :destroy, class_name: 'Notification', inverse_of: :circle

  has_many :posts_as_creator, class_name: 'Post', inverse_of: :account, dependent: :destroy
  has_many :subscriptions_as_creator, class_name: 'Subscription', inverse_of: :account, dependent: :destroy
  has_many :comments_as_creator, class_name: 'Comment', inverse_of: :account, dependent: :destroy
  has_many :comment_reactions_as_creator, class_name: 'CommentReaction', inverse_of: :account, dependent: :destroy

  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy

  has_many :orders, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :donations, dependent: :destroy

  # Dragonfly
  dragonfly_accessor :picture do
    #    after_assign do |attachment|
    #      attachment.convert! '-auto-orient'
    #    end
  end
  before_validation do
    if self.picture
      begin
        self.picture.format
      rescue
        self.picture = nil
      end
    end
  end

  def picture_thumb_or_gravatar_url
    picture ? picture.thumb('400x400#').url : (Padrino.env == :development ? '/images/silhouette.png' : "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=400&d=#{URI.encode("#{ENV['BASE_URI']}/images/silhouette.png")}")
  end

  def unread_notifications?
    last_checked_notifications && (n = network_notifications.order('created_at desc').first) && n.created_at > last_checked_notifications
  end

  has_many :provider_links, dependent: :destroy
  accepts_nested_attributes_for :provider_links

  attr_accessor :password, :postcode

  validates_presence_of :name, :username, :email
  validates_length_of       :email,    within: 3..100
  validates_uniqueness_of   :email,    case_sensitive: false
  validates_format_of       :email,    with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i
  validates_presence_of     :password, :if => :password_required
  validates_length_of       :password, within: 4..40, :if => :password_required

  validates_format_of :username, with: /\A[a-z0-9_\.]+\z/
  validates_uniqueness_of :username

  def self.default_currencies
    [''] + %w[GBP EUR USD SEK DKK]
  end

  def currency_symbol
    Gathering.currency_symbol(default_currency)
  end
    
  def self.admin_fields
    {
      email: :email,
      name: :text,
      name_transliterated: { type: :text, disabled: true },
      ps_account_id: :text,
      updated_profile: :check_box,
      facebook_name: :text,
      default_currency: :select,      
      phone: :text,
      telegram_username: :text,
      location: :text,
      username: :text,
      website: :url,
      gender: :select,
      sexuality: :select,
      date_of_birth: :date,
      facebook_profile_url: :text,
      dietary_requirements: :text,
      picture: :image,
      admin: :check_box,
      unsubscribed: :check_box,
      unsubscribed_habit_completion_likes: :check_box,
      unsubscribed_messages: :check_box,
      unsubscribed_feedback: :check_box,
      not_on_facebook: :check_box,
      time_zone: :select,
      password: :password,
      provider_links: :collection,
      sign_ins: :number,
      memberships: :collection,
      mapplications: :collection,
      last_active: :datetime,
      stripe_connect_json: :text_area
    }
  end

  def self.new_hints
    {
      password: 'Leave blank to keep existing password'
    }
  end

  def self.edit_hints
    new_hints
  end

  def self.new_tips
    {
      username: 'Letters, numbers, underscores and periods',
      phone: 'Visible only to people in your gatherings',
      telegram_username: 'Visible only to people in your gatherings'
    }
  end

  def self.edit_tips
    new_tips
  end

  def self.sexualities
    [''] + %(Straight
Gay
Bisexual
Asexual
Demisexual
Heteroflexible
Homoflexible
Lesbian
Pansexual
Queer
Questioning
Sapiosexual).split("\n")
  end

  def self.genders
    [''] + %(Woman
Man
Agender
Androgynous
Bigender
Cis Man
Cis Woman
Genderfluid
Genderqueer
Gender Nonconforming
Hijra
Intersex
Non-binary
Other
Pangender
Transfeminine
Transgender
Transmasculine
Transsexual
Trans Man
Trans Woman
Two Spirit).split("\n")
  end

  def age
    if dob = date_of_birth
      now = Time.now.utc.to_date
      now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
    end
  end

  def self.radio_scopes
    x = []
    x
  end

  def self.check_box_scopes
    y = []

    y << [:open_to_new_friends, 'Open to new friends', where(open_to_new_friends: true)]
    y << [:open_to_hookups, 'Open to hookups', where(open_to_hookups: true)]
    y << [:open_to_short_term_dating, 'Open to short-term dating', where(open_to_short_term_dating: true)]
    y << [:open_to_long_term_dating, 'Open to long-term dating', where(open_to_long_term_dating: true)]
    y << [:open_to_open_relating, 'Open to open relating', where(open_to_open_relating: true)]

    y
  end

  def self.human_attribute_name(attr, options = {})
    {
      facebook_profile_url: 'Facebook profile URL',
      not_on_facebook: "I don't use Facebook",
      unsubscribed: "Don't send me email notifications of any kind",
      unsubscribed_habit_completion_likes: "Don't send me email notifications when people like my habit completions",
      unsubscribed_messages: "Don't send me email notifications of messages",
      unsubscribed_feedback: "Don't send me requests for feedback"
    }[attr.to_sym] || super
  end

  def firstname
    if !name.blank?
      parts = name.split(' ')
      if parts.count > 1 && %w{mr mrs ms dr}.include?(parts[0].downcase.gsub('.',''))
        n = parts[1]
      else
        n = parts[0]
      end
      n.capitalize
    end
  end
  
  def lastname
    if name
      nameparts = name.split(' ')
      if nameparts.length > 1
        nameparts[1..-1].join(' ') 
      else
        nil
      end
    end
  end  
  
  def abbrname
    if firstname
      firstname.capitalize + (lastname ? (' ' + lastname[0].upcase + '.') : '')
    end
  end 

  def self.time_zones
    [''] + ActiveSupport::TimeZone::MAPPING.keys.sort
  end

  def uid
    id
  end

  def info
    { email: email, name: name }
  end

  def self.authenticate(email, password)
    account = find_by(email: /^#{::Regexp.escape(email)}$/i) if email.present?
    if account
      account.has_password?(password) ? account : nil
    end
  end

  before_save :encrypt_password, :if => :password_required

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  def self.generate_password(len)
    chars = ('a'..'z').to_a + ('0'..'9').to_a
    Array.new(len) { chars[rand(chars.size)] }.join
  end

  def reset_password!
    self.password = Account.generate_password(8)
    if save
      
      mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
      batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
    
      account = self
      content = ERB.new(File.read(Padrino.root('app/views/emails/reset_password.erb'))).result(binding)
      batch_message.from ENV['NOTIFICATION_EMAIL']
      batch_message.subject 'New password for Autopia'
      batch_message.body_html ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
                
      [account].each { |account|
        batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id})
      }
        
      batch_message.finalize
    
    else
      return false
    end
  end

  private

  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(password)
  end

  def password_required
    crypted_password.blank? || password.present?
  end
end
