class Cultivation
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :quality, index: true
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  before_validation do
    self.group = self.quality.group if self.quality
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  validates_uniqueness_of :quality, :scope => :account
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => quality.group, :type => 'cultivating_quality'
  end      
        
  def self.admin_fields
    {
      :quality_id => :lookup,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
    
end
