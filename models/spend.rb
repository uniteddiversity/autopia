class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean

  belongs_to :group, index: true
  belongs_to :account, index: true
  belongs_to :membership, index: true 
  
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
    
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'listed_spend'
  end
          
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :reimbursed => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup,
      :membership_id => :lookup
    }
  end
  
end
