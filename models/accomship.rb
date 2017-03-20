class Accomship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :accom, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  validates_uniqueness_of :account, :scope => :group
  
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'joined_accom'
  end      
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :accom_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  after_save do membership.update_requested_contribution end
  after_destroy do membership.update_requested_contribution end
  
  before_validation do
    errors.add(:accom, 'is full') if accom and accom.capacity and accom.accomships.count == accom.capacity
  end
    
end
