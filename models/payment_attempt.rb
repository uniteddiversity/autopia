class PaymentAttempt
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  # has_one :payment_attempt, :dependent => :nullify
  
	field :gathering_name, :type => String
  field :amount, :type => Integer
  field :currency, :type => String
  field :session_id, :type => String
    
  validates_presence_of :gathering_name, :amount, :currency

  before_validation do  	
  	self.account = self.membership.account if self.membership
    self.gathering = self.membership.gathering if self.membership
    self.gathering_name = self.gathering.name if self.gathering    
  end    

  def self.admin_fields
    {
      :session_id => :text,
      :account_id => :lookup,
      :gathering_id => :lookup,
      :membership_id => :lookup,
      :gathering_name => :text,
      :currency => :text,
      :amount => :number      
    }
  end
    
end
