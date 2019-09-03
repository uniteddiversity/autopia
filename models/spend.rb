class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean
  
  validates_presence_of :item, :amount

  belongs_to :team, index: true
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  belongs_to :membership, index: true 
  
  before_validation do
    self.membership = self.gathering.memberships.find_by(account: self.account) if self.gathering and self.account and !self.membership
  end    
    
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'created_spend'
  end
  
  def circle
    gathering
  end
          
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :team_id => :lookup,
      :reimbursed => :check_box,
      :gathering_id => :lookup,      
      :account_id => :lookup,
      :membership_id => :lookup
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :amount => 'Cost',
      :account_id => 'Paid by',
    }[attr.to_sym] || super  
  end    
  
end
