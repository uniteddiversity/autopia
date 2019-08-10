class Cultivation
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :quality, index: true
  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  
  before_validation do
    self.gathering = self.quality.gathering if self.quality
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
  end  
  
  validates_uniqueness_of :quality, :scope => :account
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => quality.gathering, :type => 'cultivating_quality'
  end      
        
  def self.admin_fields
    {
      :quality_id => :lookup,
      :account_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup
    }
  end
    
end
