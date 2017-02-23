class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean

  belongs_to :group
  belongs_to :account
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'listed_spend'
  end
  
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
