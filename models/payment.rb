class Payment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  
	field :group_name, :type => String
  field :amount, :type => Integer
  field :currency, :type => String
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_payment'
  end
  
  validates_presence_of :group_name, :amount, :currency

  before_validation do  	
  	self.account = self.membership.account if self.membership
    self.group = self.membership.group if self.membership
    self.group_name = self.group.name if self.group    
  end    

  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :group_name => :text,
      :currency => :text,
      :amount => :number
    }
  end
    
end
