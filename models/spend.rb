class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean

  belongs_to :gathering
  belongs_to :account
  
  validates_presence_of :gathering, :account
        
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :reimbursed => :check_box,
      :gathering_id => :lookup,      
      :account_id => :lookup      
    }
  end
    
end
