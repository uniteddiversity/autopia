class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  dragonfly_accessor :image
  
  field :name, :type => String
  field :slug, :type => String
  field :image_uid, :type => String
  field :facebook_group, :type => String
  field :application_preamble, :type => String
  field :application_questions, :type => String
  field :anonymous_supporters, :type => Boolean
  field :anonymous_blockers, :type => Boolean
  field :democratic_threshold, :type => Boolean
  field :fixed_threshold, :type => Integer
  field :payment_details, :type => String
  field :ask_for_date_of_birth, :type => Boolean
  field :ask_for_gender, :type => Boolean
  field :ask_for_poc, :type => Boolean
  field :featured, :type => Boolean
  field :member_limit, :type => Integer
  
  before_validation do
    self.featured = true if self.featured.nil?
  end
  
  belongs_to :account
  
  validates_presence_of :name, :slug, :account
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy
  has_many :spends, :dependent => :destroy
  has_many :rotas, :dependent => :destroy
  has_many :teams, :dependent => :destroy
  has_many :tiers, :dependent => :destroy
  has_many :transports, :dependent => :destroy
  has_many :accoms, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  
  has_many :spaces, :dependent => :destroy
  has_many :tslots, :dependent => :destroy
  
  def application_questions_a
    q = (application_questions || '').split("\n").map(&:strip) 
    q.empty? ? [] : q
  end  
  
  def members
    Account.where(:id.in => memberships.pluck(:account_id))
  end
  
  def admin_emails
    Account.where(:stop_emails.ne => true).where(:id.in => memberships.where(admin: true).pluck(:account_id)).pluck(:email)
  end
  
  def emails
    Account.where(:stop_emails.ne => true).where(:id.in => memberships.pluck(:account_id)).pluck(:email)
  end  
  
  def anonymous_proposers
    false
  end
        
  def self.admin_fields
    {
      :name => :text,
      :slug => :slug,      
      :image => :image,
      :facebook_group => :text,
      :fixed_threshold => :number,
      :member_limit => :number,
      :democratic_threshold => :check_box,
      :application_preamble => :wysiwyg,
      :application_questions => :text_area,
      :anonymous_supporters => :check_box,
      :anonymous_blockers => :check_box,
      :ask_for_date_of_birth => :check_box,
      :ask_for_gender => :check_box,
      :ask_for_poc => :check_box,
      :featured => :check_box,
      :payment_details => :text_area,
      :account_id => :lookup,
      :memberships => :collection,
      :mapplications => :collection,
      :spends => :collection,
      :rotas => :collection,
      :teams => :collection
    }
  end
  
  def self.new_tips
    {      
      :facebook_group => 'URL of any associated Facebook group',
      :application_questions => 'One per line',
      :democratic_threshold => 'Setting a magic number results in applications with a certain number of proposers + supporters (including at least one proposer) being accepted automatically. A democratic magic number means all group members have a say over the number.',
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
