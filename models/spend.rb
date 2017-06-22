class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :category, :type => String
  field :reimbursed, :type => Boolean
  
  validates_presence_of :item, :amount

  belongs_to :group, index: true
  belongs_to :account, index: true
  belongs_to :membership, index: true 
  
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
    
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_spend'
  end
          
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :category => :text,
      :reimbursed => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup,
      :membership_id => :lookup
    }
  end
  
end
