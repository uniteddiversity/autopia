class Transportship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :transport, index: true 
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  validates_uniqueness_of :account, :scope => :transport
    
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end   
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'joined_transport'
  end      
           
  def self.admin_fields
    {
      :account_id => :lookup,
      :transport_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  after_save do membership.update_requested_contribution end
  after_destroy do membership.try(:update_requested_contribution) end
  
  before_validation do
    errors.add(:transport, 'is full') if transport and transport.capacity and transport.transportships.count == transport.capacity
  end  
      
end
