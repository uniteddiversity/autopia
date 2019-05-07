class PaymentAttempt
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  belongs_to :membership, index: true
  has_one :payment_attempt, :dependent => :nullify
  
	field :group_name, :type => String
  field :amount, :type => Integer
  field :currency, :type => String
  field :session_id, :type => String
    
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
      :amount => :number,
      :session_id => :text
    }
  end
    
end
