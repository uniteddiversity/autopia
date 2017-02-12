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
  field :threshold, :type => Integer
  field :payment_details, :type => String
  
  belongs_to :account
  
  validates_presence_of :name, :slug, :account
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy
  has_many :spends, :dependent => :destroy
  has_many :rotas, :dependent => :destroy
  has_many :teams, :dependent => :destroy
  
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
      :threshold => :number,
      :application_preamble => :wysiwyg,
      :application_questions => :text_area,
      :anonymous_supporters => :check_box,
      :anonymous_blockers => :check_box,
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
      :threshold => 'Automatically accept applications with this many supporters + proposers'
    }
  end
  
  def self.edit_tips
    self.new_tips
  end  
    
end
