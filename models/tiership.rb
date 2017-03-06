class Tiership
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :tier, index: true
  belongs_to :group, index: true
  
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
  
  def membership
    group.memberships.find_by(account: account)
  end
  after_save do membership.update_requested_contribution end
  after_destroy do membership.update_requested_contribution end
      
end
