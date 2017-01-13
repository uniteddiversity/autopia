class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean

  belongs_to :group
  belongs_to :account
  
  validates_presence_of :group, :account
        
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :reimbursed => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup      
    }
  end
    
end
