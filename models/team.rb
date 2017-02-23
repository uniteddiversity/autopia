class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  belongs_to :group
  belongs_to :account
  validates_presence_of :group, :account
  
  has_many :teamships, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_team'
  end      
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :group_id => :lookup,
      :account_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
