class Withdrawal
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group, index: true
  
	field :group_name, :type => String
  field :amount, :type => Float
  field :currency, :type => String
    
  validates_presence_of :group_name, :amount, :currency

  before_validation do
    self.group_name = self.group.name if self.group    
    self.currency = self.group.currency if self.group
  end    

  def self.admin_fields
    {
      :group_id => :lookup,
      :group_name => {:type => :text, :disabled => true},
      :currency => {:type => :text, :disabled => true},
      :amount => :number
    }
  end
  
  after_create do
    group.update_attribute(:balance, group.balance - amount)
  end
    
end
