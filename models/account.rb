class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model
            
  field :name, :type => String  
  field :name_transliterated, :type => String
  field :email, :type => String
  field :username, :type => String
  field :website, :type => String
  field :gender, :type => String
  field :date_of_birth, :type => Date
  field :dietary_requirements, :type => String
  field :admin, :type => Boolean
  field :time_zone, :type => String
  field :crypted_password, :type => String
  field :picture_uid, :type => String
  field :sign_ins, :type => Integer
  field :sign_in_token, :type => String  
  field :unsubscribed, :type => Boolean
  field :unsubscribed_habit_completion_likes, :type => Boolean
  field :unsubscribed_messages, :type => Boolean
  field :facebook_name, :type => String 
  field :facebook_profile_url, :type => String  
  field :not_on_facebook, :type => Boolean
  field :last_active, :type => Time
  field :last_checked_notifications, :type => Time
  field :location, :type => String
  field :coordinates, :type => Array
  field :open_to_hookups, :type => Boolean
  field :open_to_new_friends, :type => Boolean
  field :open_to_short_term_dating, :type => Boolean
  field :open_to_long_term_dating, :type => Boolean
  field :open_to_non_monogamy, :type => Boolean
  field :default_currency, :type => String
  
  def self.open_to
    %w{new_friends hookups short_term_dating long_term_dating non_monogamy}
  end
  
  def open_to
    Account.open_to.select { |x| self.send("open_to_#{x}") }
  end
    
  def self.protected_attributes
    %w{admin}
  end
      
  before_validation do
    if !self.username and self.name
      u = self.name.parameterize.underscore
      n = Account.where(username: u).count
      if n > 0
        u = "#{u}#{n}"
      end
      self.username = u
    end
    self.sign_in_token = SecureRandom.uuid if !self.sign_in_token
    self.name = self.name.strip if self.name
    self.name_transliterated = I18n.transliterate(self.name) if self.name
    self.username = self.username.downcase if self.username
    
    errors.add(:name, 'must not contain an @') if self.name and self.name.include?('@')
    errors.add(:email, 'must not contain commas') if self.email and self.email.include?(',')    
    
    errors.add(:facebook_profile_url, 'must contain facebook.com') if self.facebook_profile_url and !self.facebook_profile_url.include?('facebook.com')    
    self.facebook_profile_url = "https://#{self.facebook_profile_url}" if self.facebook_profile_url and !(self.facebook_profile_url =~ /\Ahttps?:\/\//)
    self.facebook_profile_url = self.facebook_profile_url.gsub('m.facebook.com','facebook.com') if self.facebook_profile_url
    
    errors.add(:date_of_birth, 'is invalid') if self.age && self.age <= 0
  end
  
  # Geocoder
  geocoded_by :location  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end
  
  def self.marker_color
    'green'
  end  
  
  def network
    Account.where(:id.in => follows_as_follower.pluck(:followee_id))
  end
  
  def groupies
    Account.where(:id.in => Membership.where(:group_id.in => memberships.pluck(:group_id)).pluck(:account_id))
  end
  
  def subscribers    
    Account.where(:unsubscribed.ne => true).where(:id.in => [id] + follows_as_followee.where(:unsubscribed.ne => true).pluck(:follower_id))
  end
  
  def emails
    subscribers.pluck(:email)
  end
  
  def network_notifications
    Notification.or(
      {:circle_type => 'Group', :circle_id.in => memberships.pluck(:group_id)},
      {:circle_type => 'Account', :circle_id.in => [id] + network.pluck(:id)},
      {:circle_type => 'Place', :circle_id.in => places_following.pluck(:id)}
    )
  end  
  
  has_many :places, :dependent => :nullify
  
  has_many :groups, :dependent => :nullify  
    
  has_many :mapplications, :class_name => "Mapplication", :inverse_of => :account, :dependent => :destroy
  has_many :mapplications_processed, :class_name => "Mapplication", :inverse_of => :processed_by, :dependent => :nullify  
  
  has_many :verdicts, :dependent => :destroy
  
  has_many :memberships, :class_name => "Membership", :inverse_of => :account, :dependent => :destroy
  has_many :memberships_added, :class_name => "Membership", :inverse_of => :added_by, :dependent => :nullify    
  has_many :memberships_admin_status_changed, :class_name => "Membership", :inverse_of => :admin_status_changed_by, :dependent => :nullify    
  
  has_many :payments, :dependent => :destroy
  has_many :payment_attempts, :dependent => :destroy
      
  # Timetable
  has_many :timetables, :dependent => :nullify
  has_many :activities, :class_name => "Activity", :inverse_of => :account, :dependent => :destroy
  has_many :activities_scheduled, :class_name => "Activity", :inverse_of => :scheduled_by, :dependent => :nullify    
  has_many :attendances, :dependent => :destroy
  # Teams
  has_many :teams, :dependent => :nullify  
  has_many :teamships, :dependent => :destroy 
  has_many :read_receipts, :dependent => :destroy
  has_many :options, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  # Rotas
  has_many :rotas, :dependent => :nullify  
  has_many :shifts, :dependent => :destroy
  # Tiers
  has_many :tiers, :dependent => :nullify  
  has_many :tierships, :dependent => :destroy 
  # Accommodation
  has_many :accoms, :dependent => :nullify        
  has_many :accomships, :dependent => :destroy  
  # Transport
  has_many :transports, :dependent => :nullify
  has_many :transportships, :dependent => :destroy 
  # Budget
  has_many :spends, :dependent => :destroy
  # Qualities
  has_many :qualities, :dependent => :nullify
  has_many :cultivations, :dependent => :destroy
  # Inventory
  has_many :inventory_items_listed, :class_name => 'InventoryItem', :inverse_of => :account, :dependent => :nullify
  has_many :inventory_items_provided, :class_name => 'InventoryItem', :inverse_of => :responsible, :dependent => :nullify
  # Habits
  has_many :habits, :dependent => :destroy
  has_many :habit_completions, :dependent => :destroy
  has_many :habit_completion_likes, :dependent => :destroy
  # Follows
  has_many :follows_as_follower, :class_name => "Follow", :inverse_of => :follower, :dependent => :destroy
  has_many :follows_as_followee, :class_name => "Follow", :inverse_of => :followee, :dependent => :destroy  
  # Messages
  has_many :messages_as_messenger, :class_name => "Message", :inverse_of => :messenger, :dependent => :destroy
  has_many :messages_as_messengee, :class_name => "Message", :inverse_of => :messengee, :dependent => :destroy  
  def messages
    Message.or({:messenger => self},{:messengee => self})
  end
  # MessageReceipts
  has_many :message_receipts_as_messenger, :class_name => "MessageReceipt", :inverse_of => :messenger, :dependent => :destroy
  has_many :message_receipts_as_messengee, :class_name => "MessageReceipt", :inverse_of => :messengee, :dependent => :destroy
  # Placeships
  has_many :placeships, :dependent => :destroy
  def places_following; Place.where(:id.in => placeships.pluck(:place_id)); end
  has_many :placeship_categories, :dependent => :destroy
  # Rooms
  has_many :rooms, :dependent => :destroy
  has_many :room_attachments, :dependent => :destroy
  has_many :room_periods, :dependent => :destroy
  
  has_many :notifications_as_notifiable, :as => :notifiable, :dependent => :destroy, :class_name => "Notification", :inverse_of => :notifiable
  has_many :notifications_as_circle, :as => :circle, :dependent => :destroy, :class_name => "Notification", :inverse_of => :circle
  
  has_many :posts_as_creator, :class_name => "Post", :inverse_of => :account, :dependent => :destroy
  has_many :subscriptions_as_creator, :class_name => "Subscription", :inverse_of => :account, :dependent => :destroy
  has_many :comments_as_creator,  :class_name => "Comment", :inverse_of => :account, :dependent => :destroy
  has_many :comment_reactions_as_creator, :class_name => "CommentReaction", :inverse_of => :account, :dependent => :destroy  
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy
    
  # Dragonfly
  dragonfly_accessor :picture do  
    after_assign do |attachment|
      attachment.convert! '-auto-orient'
    end  
  end
  before_validation do
    if self.picture
      begin
        self.picture.format
      rescue        
        errors.add(:picture, 'must be an image')
      end
    end
  end   
  attr_accessor :rotate_picture_by
  before_validation :rotate_picture
  def rotate_picture
    if self.picture and self.rotate_picture_by
      picture.rotate(self.rotate_picture_by)
    end  
  end  
  
  def picture_thumb_or_gravatar_url
    picture ? picture.thumb('400x400#').url : (Padrino.env == :development ? '/images/silhouette.png' : "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=400&d=#{URI::encode("#{ENV['BASE_URI']}/images/silhouette.png")}")
  end  
  
  def unread_notifications?
    last_checked_notifications && (n = network_notifications.order('created_at desc').first) && n.created_at > last_checked_notifications
  end
    
  has_many :provider_links, :dependent => :destroy
  accepts_nested_attributes_for :provider_links  
          
  attr_accessor :password  

  validates_presence_of :name, :username, :email
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email,    :case_sensitive => false
  validates_format_of       :email,    :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i
  validates_presence_of     :password,                   :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
  
  validates_format_of :username, :with => /\A[a-z0-9_\.]+\z/
  validates_uniqueness_of :username
  
  def self.default_currencies
    [''] + %w{GBP EUR USD SEK DKK}
  end
  
  def currency_symbol
    Group.currency_symbol(default_currency)
  end   
            
  def self.admin_fields
    {
      :name => :text,
      :name_transliterated => {:type => :text, :disabled => true},
      :facebook_name => :text,
      :default_currency => :select,
      :email => :text,
      :username => :text,
      :website => :url,
      :gender => :select,
      :date_of_birth => :date,
      :facebook_profile_url => :text,
      :dietary_requirements => :text,
      :picture => :image,
      :admin => :check_box,
      :unsubscribed => :check_box,
      :unsubscribed_habit_completion_likes => :check_box,
      :unsubscribed_messages => :check_box,
      :not_on_facebook => :check_box,
      :time_zone => :select,
      :password => :password,
      :provider_links => :collection,
      :sign_ins => :number,
      :memberships => :collection,
      :mapplications => :collection,
      :last_active => :datetime
    }
  end
  
  def self.new_hints
    {
      :email => 'Shown only to people in your groups',
      :password => 'Leave blank to keep existing password'
    }
  end   
  
  def self.edit_hints
    self.new_hints
  end    
  
  def self.new_tips
    {
      :gender => 'Optional. Please only provide this information if you feel comfortable doing so',
      :date_of_birth => 'Optional. Please only provide this information if you feel comfortable doing so',
      :facebook_profile_url => 'Optional. Please only provide this information if you feel comfortable doing so',
      :username => 'Letters, numbers, underscores and periods'
    }
  end
  
  def self.edit_tips
    self.new_tips
  end
  
  def self.genders
    [''] + %w{Nonbinary Woman Man}
  end  
  
  def self.gender_symbol(gender, pluralize: false)
    case gender
    when 'Man'
      %Q{<i data-toggle="tooltip" title="#{pluralize ? 'Men' : 'Man'}" class="fa fa-mars"></i>}
    when 'Woman'
      %Q{<i data-toggle="tooltip" title="#{pluralize ? 'Women' : 'Woman'}" class="fa fa-venus"></i>}
    when 'Nonbinary'
      '<i data-toggle="tooltip" title="Nonbinary" class="fa fa-transgender"></i>'
    end
  end

  def gender_symbol
    Account.gender_symbol(gender)
  end
  
  def age    
    if dob = date_of_birth
      now = Time.now.utc.to_date
      now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
    end
  end 
  
  def self.radio_scopes
    x = []

    x << [:gender, 'all', 'All genders', all]
    Account.genders.reject(&:blank?).each { |gender|
      x << [:gender, gender, gender == 'Nonbinary' ? 'Nonbinary' : gender.pluralize, where(:gender => gender)]
    }
    
    x
  end  
  
  def self.check_box_scopes
    y = []
    
    y << [:open_to_new_friends, 'Open to new friends', where(:open_to_new_friends => true)]
    y << [:open_to_hookups, 'Open to hookups', where(:open_to_hookups => true)]
    y << [:open_to_short_term_dating, 'Open to short-term dating', where(:open_to_short_term_dating => true)]
    y << [:open_to_long_term_dating, 'Open to long-term dating', where(:open_to_long_term_dating => true)]
    y << [:open_to_non_monogamy, 'Open to non-monogamy', where(:open_to_non_monogamy => true)]   
    
    y
  end  
  
  def self.human_attribute_name(attr, options={})  
    {
      :facebook_profile_url => 'Facebook profile URL',
      :not_on_facebook => "I don't use Facebook",
      :unsubscribed => "Don't send me email notifications of any kind",
      :unsubscribed_habit_completion_likes => "Don't send me email notifications when people like my habit completions",
      :unsubscribed_messages => "Don't send me email notifications of messages",
    }[attr.to_sym] || super  
  end   
  
  def firstname
    name.split(' ').first
  end
               
  def self.time_zones
    ['']+ActiveSupport::TimeZone::MAPPING.keys.sort
  end  
      
  def uid
    id
  end
  
  def info
    {:email => email, :name => name}
  end
  
  def self.authenticate(email, password)
    account = find_by(email: /^#{::Regexp.escape(email)}$/i) if email.present?
    account && account.has_password?(password) ? account : nil
  end
  
  before_save :encrypt_password, :if => :password_required

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  def self.generate_password(len)
    chars = ("a".."z").to_a + ("0".."9").to_a
    return Array.new(len) { chars[rand(chars.size)] }.join
  end   
  
  def reset_password!
    self.password = Account.generate_password(8)
    if self.save
      mail = Mail.new
      mail.to = self.email
      mail.from = ENV['NOTIFICATION_EMAIL']
      mail.subject = "New password for Autopia"
      mail.body = "Hi #{self.firstname},\n\nSomeone (hopefully you) requested a new password on Autopia.\n\nYour new password is: #{self.password}\n\nYou can sign in at #{ENV['BASE_URI']}/accounts/sign_in."
      mail.deliver       
    else
      return false
    end
  end

  private
  
  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(self.password)
  end

  def password_required
    crypted_password.blank? || self.password.present?
  end  
end
