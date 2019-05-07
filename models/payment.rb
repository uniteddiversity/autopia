class Payment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  belongs_to :payment_attempt, index: true, optional: true
  
	field :group_name, :type => String
  field :amount, :type => Integer
  field :currency, :type => String
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => group, :type => 'created_payment'
  end
  
  validates_presence_of :group_name, :amount, :currency

  before_validation do  	
    if self.payment_attempt
      self.membership = self.payment_attempt.membership
      self.amount = self.payment_attempt.amount
      self.currency = self.payment_attempt.currency
    end
  	self.account = self.membership.account if self.membership
    self.group = self.membership.group if self.membership
    self.group_name = self.group.name if self.group    
  end    
  
  after_create do
    membership.update_attribute(:paid, membership.paid + amount)
    group.update_attribute(:processed_via_stripe, group.processed_via_stripe + amount)
    group.update_attribute(:balance, group.balance + amount*0.95)    
  end

  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :payment_attempt_id => :lookup,
      :group_name => :text,
      :currency => :text,
      :amount => :number
    }
  end
    
end
