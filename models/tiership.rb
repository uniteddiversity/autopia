class Tiership
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :tier
  belongs_to :group
  
  validates_presence_of :account, :tier, :group
  validates_uniqueness_of :account, :scope => :group
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'joined_tier'
  end    
           
  def self.admin_fields
    {
      :account_id => :lookup,
      :tier_id => :lookup,
      :group_id => :lookup
    }
  end
      
end
