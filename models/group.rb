class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  dragonfly_accessor :image
  
  field :name, :type => String
  field :slug, :type => String
  field :image_uid, :type => String
  field :facebook_group, :type => String
  field :request_questions, :type => String
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  has_many :memberships, :dependent => :destroy
  has_many :mapplications, :dependent => :destroy
  has_many :spends, :dependent => :destroy
  has_many :rotas, :dependent => :destroy
  has_many :teams, :dependent => :destroy
  
  def request_questions_a
    q = (request_questions || '').split("\n").map(&:strip) 
    q.empty? ? [] : q
  end  
  
  def members
    Account.where(:id.in => memberships.pluck(:account_id))
  end
  
#  after_create do
#    [  
#      'Admin, payment and grants',
#      'Transport and strike',
#      'Food',
#      'Toilets',
#      'Circles/community',
#      'Consent',
#      'Psychedelic welfare',
#      'Power, Privilege & Inclusion',
#      'Photography',
#      'Leave No Trace'
#    ].each { |team_name|
#      teams.create(name: team_name)
#    }
#    food = rotas.create(name: 'Food/kitchen')
#    [
#      'Kitchen lead',
#      'Kitchen 2',
#      'Kitchen 3',
#      'Kitchen 4',
#      'Kitchen 5',
#      'Kitchen 6',
#      'Wash up 1',
#      'Wash up 2',
#      'Wash up 3',
#      'Wash up 4',
#    ].each { |rota_role_name|
#      food.rota_roles.create name: rota_role_name
#    }
#    [
#      'Thurs dinner',
#      'Fri breakfast',
#      'Fri lunch',
#      'Fri dinner',
#      'Sat breakfast',
#      'Sat lunch',
#      'Sat dinner',
#      'Sun breakfast',
#      'Sun lunch'
#    ].each { |slot_name|
#      food.slots.create name: slot_name
#    }    
#  end
        
  def self.admin_fields
    {
      :name => :text,
      :slug => :slug,
      :image => :image,
      :facebook_group => :text,
      :request_questions => :text_area,
      :memberships => :collection,
      :mapplications => :collection,
      :spends => :collection,
      :rotas => :collection,
      :teams => :collection
    }
  end
    
end
