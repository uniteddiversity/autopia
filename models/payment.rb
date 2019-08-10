class Payment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  belongs_to :payment_attempt, index: true, optional: true
  
	field :gathering_name, :type => String
  field :amount, :type => Integer
  field :currency, :type => String
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => gathering, :type => 'created_payment'
  end
  
  validates_presence_of :gathering_name, :amount, :currency

  before_validation do  	
    if self.payment_attempt
      self.membership = self.payment_attempt.membership
      self.amount = self.payment_attempt.amount
      self.currency = self.payment_attempt.currency
    end
  	self.account = self.membership.account if self.membership
    self.gathering = self.membership.gathering if self.membership
    self.gathering_name = self.gathering.name if self.gathering    
  end    
  
  after_create do
    membership.update_attribute(:paid, membership.paid + amount)
    gathering.update_attribute(:processed_via_stripe, gathering.processed_via_stripe + amount)
    gathering.update_attribute(:balance, gathering.balance + amount*0.95)    
  end

  def self.admin_fields
    {
      :account_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup,
      :payment_attempt_id => :lookup,
      :gathering_name => :text,
      :currency => :text,
      :amount => :number
    }
  end
    
end
