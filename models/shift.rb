class Shift
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account, index: true
  belongs_to :role, index: true
  belongs_to :rslot, index: true
  belongs_to :rota, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
  validates_presence_of :role, :rslot, :rota, :group
  validates_uniqueness_of :role, :scope => :rslot
  
  before_validation do
    self.rota = self.role.rota if self.role
    self.group = self.rota.group if self.rota
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :group => rota.group, :type => 'signed_up_to_a_shift'
    end
  end  
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :role_id => :lookup,
      :rslot_id => :lookup,    
      :rota_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
      
end
