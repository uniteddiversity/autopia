class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  dragonfly_accessor :image
  
  def self.enablable
    %w{qualities timetables teams rotas tiers bookings accommodation transport budget}
  end  
  
  field :name, :type => String
  field :slug, :type => String
  field :image_uid, :type => String
  field :intro_for_members, :type => String
  field :application_preamble, :type => String
  field :application_questions, :type => String
  field :anonymous_supporters, :type => Boolean
  field :anonymous_blockers, :type => Boolean
  field :democratic_threshold, :type => Boolean
  field :fixed_threshold, :type => Integer
  field :ask_for_date_of_birth, :type => Boolean
  field :ask_for_gender, :type => Boolean
  field :ask_for_poc, :type => Boolean
  field :featured, :type => Boolean
  field :member_limit, :type => Integer
  field :booking_limit, :type => Integer
  field :balance, :type => Integer
  field :paypal_email, :type => String
  enablable.each { |x|
    field :"enable_#{x}", :type => Boolean
  }
    
  before_validation do
    self.featured = true if self.featured.nil?
    self.balance = 0 if self.balance.nil?
  end
  
  belongs_to :account, index: true
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy  
  has_many :notifications, :dependent => :destroy
  has_many :verdicts, :dependent => :destroy
  
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
    Account.where(:stop_emails.ne => true).where(:id.in => memberships.where(admin: true).pluck(:account_id)).pluck(:email)
  end
  
  def emails
    Account.where(:stop_emails.ne => true).where(:id.in => memberships.pluck(:account_id)).pluck(:email)
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
  
  def anonymous_proposers
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
      :balance => :number,
      :democratic_threshold => :check_box,
      :application_preamble => :wysiwyg,
      :application_questions => :text_area,
      :anonymous_supporters => :check_box,
      :anonymous_blockers => :check_box,
      :ask_for_date_of_birth => :check_box,
      :ask_for_gender => :check_box,
      :ask_for_poc => :check_box,
      :featured => :check_box,
      :paypal_email => :text,
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
  
  def self.new_tips
    {      
      :application_questions => 'One per line',
      :democratic_threshold => 'Setting a magic number results in applications with a certain number of proposers + supporters (with at least one proposer) being accepted automatically. A democratic magic number means all group members have a say over the number.',
      :fixed_threshold => 'Takes precedence over democratic magic number'
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :ask_for_poc => 'Ask whether applicants identify as a person of colour',
      :democratic_threshold => 'Democratic magic number',
      :fixed_threshold => 'Fixed magic number'
    }[attr.to_sym] || super  
  end   
  
  def self.edit_tips
    self.new_tips
  end  
    
  def threshold
    fixed_threshold ? fixed_threshold : (median_threshold if democratic_threshold)
  end
  
  before_validation do
    if fixed_threshold
      self.democratic_threshold = false
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
