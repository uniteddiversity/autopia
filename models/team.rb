class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :intro, :type => String
  field :budget, :type => Integer
    
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name, :group
  
  has_many :teamships, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy
  
  has_many :spends, :dependent => :nullify
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    unless prevent_notifications
      notifications.create! :group => group, :type => 'created_team'
    end
  end      
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
  
  def emails
    Account.where(:id.in => teamships.pluck(:account_id)).pluck(:email)
  end  
  
  def spent
    spends.pluck(:amount).sum
  end
        
  def self.admin_fields
    {
      :name => :text,
      :intro => :wysiwyg,
      :group_id => :lookup,
      :account_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
