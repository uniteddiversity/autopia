class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
            
  field :name, :type => String
  field :facebook_name, :type => String 
  field :email, :type => String
  field :gender, :type => String
  field :date_of_birth, :type => Date
  field :facebook_profile_url, :type => String
  field :poc, :type => Boolean
  field :dietary_requirements, :type => String
  field :admin, :type => Boolean
  field :time_zone, :type => String
  field :crypted_password, :type => String
  field :picture_uid, :type => String
  field :cover_image_uid, :type => String
  field :sign_ins, :type => Integer
  field :sign_in_token, :type => String
  field :last_active, :type => Time
  field :unsubscribed, :type => Boolean
  
  before_validation do
    self.sign_in_token = SecureRandom.uuid if !self.sign_in_token
    self.name = self.name.strip if self.name
    
    errors.add(:facebook_profile_url, 'must contain facebook.com') if self.facebook_profile_url and !self.facebook_profile_url.include?('facebook.com')    
    self.facebook_profile_url = "https://#{self.facebook_profile_url}" if self.facebook_profile_url and !(self.facebook_profile_url =~ /\Ahttps?:\/\//)       
  end
  
  def network
    Account.where(:id.in => Membership.where(:group_id.in => memberships.pluck(:group_id)).pluck(:account_id))
  end
  
  def network_notifications
    Notification.where(:group_id.in => memberships.pluck(:group_id))    
  end  
  
  has_many :groups, :dependent => :nullify  
    
  has_many :mapplications, :class_name => "Mapplication", :inverse_of => :account, :dependent => :destroy
  has_many :mapplications_processed, :class_name => "Mapplication", :inverse_of => :processed_by, :dependent => :nullify  
  
  has_many :verdicts, :dependent => :destroy
  
  has_many :memberships, :class_name => "Membership", :inverse_of => :account, :dependent => :destroy
  has_many :memberships_added, :class_name => "Membership", :inverse_of => :added_by, :dependent => :nullify    
  has_many :memberships_admin_status_changed, :class_name => "Membership", :inverse_of => :admin_status_changed_by, :dependent => :nullify    
  
  has_many :payments, :dependent => :destroy
      
  # Timetable
  has_many :timetables, :dependent => :nullify
  has_many :activities, :class_name => "Activity", :inverse_of => :account, :dependent => :destroy
  has_many :activities_scheduled, :class_name => "Activity", :inverse_of => :scheduled_by, :dependent => :nullify    
  has_many :attendances, :dependent => :destroy
  # Teams
  has_many :teams, :dependent => :nullify  
  has_many :teamships, :dependent => :destroy 
  has_many :posts, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy
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
  # Bookings
  has_many :bookings, :dependent => :destroy
  has_many :booking_lifts, :dependent => :nullify
  # Qualities
  has_many :qualities, :dependent => :nullify
  has_many :cultivations, :dependent => :destroy
  # Inventory
  has_many :inventory_items_listed, :class_name => 'InventoryItem', :inverse_of => :account, :dependent => :nullify
  has_many :inventory_items_provided, :class_name => 'InventoryItem', :inverse_of => :responsible, :dependent => :nullify
  
  has_many :notifications, as: :notifiable, dependent: :destroy
    
  # Dragonfly
  dragonfly_accessor :picture 
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
  
  dragonfly_accessor :cover_image 
  before_validation do
    if self.cover_image
      begin
        self.cover_image.format
      rescue        
        errors.add(:cover_image, 'must be an image')
      end
    end
  end   
  
  has_many :provider_links, :dependent => :destroy
  accepts_nested_attributes_for :provider_links  
          
  attr_accessor :password

  validates_presence_of :name
  validates_presence_of     :email
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email,    :case_sensitive => false
  validates_format_of       :email,    :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i
  validates_presence_of     :password,                   :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
          
  def self.admin_fields
    {
      :name => :text,
      :facebook_name => :text,
      :email => :text,
      :gender => :select,
      :date_of_birth => :date,
      :facebook_profile_url => :text,
      :poc => :check_box,
      :dietary_requirements => :text,
      :picture => :image,
      :cover_image => :image,
      :admin => :check_box,
      :unsubscribed => :check_box,
      :time_zone => :select,
      :password => :password,
      :provider_links => :collection,
      :sign_ins => :number,
      :memberships => :collection
    }
  end
  
  def self.new_hints
    {
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
      :poc => 'Optional. Please only provide this information if you feel comfortable doing so',
      :facebook_profile_url => 'Optional. Please only provide this information if you feel comfortable doing so'      
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
  
  def self.human_attribute_name(attr, options={})  
    {
      :facebook_profile_url => 'Facebook profile URL',
      :poc => 'I identify as a person of colour',
      :unsubscribed => "Don't send me any email notifications of any kind"
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
    account = find_by(email: /^#{Regexp.escape(email)}$/i) if email.present?
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
      mail.subject = "New password for #{ENV['SITE_TITLE']}"
      mail.body = "Hi #{self.firstname},\n\nSomeone (hopefully you) requested a new password on #{ENV['SITE_TITLE']}.\n\nYour new password is: #{self.password}\n\nYou can sign in at #{ENV['BASE_URI']}/accounts/sign_in."
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
