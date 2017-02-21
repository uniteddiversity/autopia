class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
            
  field :name, :type => String
  field :facebook_name, :type => String 
  field :email, :type => String
  field :gender, :type => String
  field :date_of_birth, :type => Date
  field :poc, :type => Boolean
  field :dietary_requirements, :type => String
  field :admin, :type => Boolean
  field :time_zone, :type => String
  field :crypted_password, :type => String
  field :picture_uid, :type => String
  field :stop_emails, :type => Boolean
  field :sign_ins, :type => Integer
  field :sign_in_token, :type => String
  field :not_on_facebook, :type => Boolean
  
  before_validation do
    self.sign_in_token = SecureRandom.uuid if !self.sign_in_token
  end
  
  has_many :mapplications, :class_name => "Mapplication", :inverse_of => :account, :dependent => :destroy
  has_many :mapplications_processed, :class_name => "Mapplication", :inverse_of => :processed_by, :dependent => :nullify  
    
  has_many :groups, :dependent => :nullify
  has_many :memberships, :dependent => :destroy
  has_many :verdicts, :dependent => :destroy     
  has_many :activities, :dependent => :destroy
  has_many :attendances, :dependent => :destroy
  
  # Dragonfly
  dragonfly_accessor :picture  
  attr_accessor :rotate_picture_by
  before_validation :rotate_picture
  def rotate_picture
    if self.picture and self.rotate_picture_by
      picture.rotate(self.rotate_picture_by)
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
      :poc => :check_box,
      :dietary_requirements => :text,
      :picture => :image,
      :admin => :check_box,
      :time_zone => :select,
      :password => :password,
      :provider_links => :collection,
      :not_on_facebook => :check_box,
      :stop_emails => :check_box,
      :sign_ins => :number
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
      :poc => 'Optional. Please only provide this information if you feel comfortable doing so'      
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
      :not_on_facebook => "I don't use Facebook",
      :poc => 'I identify as a person of colour'
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
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "New password for Huddl"
      mail.body = "Hi #{self.firstname},\n\nSomeone (hopefully you) requested a new password on Huddl.\n\nYour new password is: #{self.password}\n\nYou can sign in at http://#{ENV['DOMAIN']}/accounts/sign_in."
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
