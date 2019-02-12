class InventoryItem
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :description, :type => String
     
  belongs_to :group, index: true
  belongs_to :account, index: true, optional: true, class_name: "Account", inverse_of: :inventory_items_listed
  belongs_to :responsible, index: true, optional: true, class_name: "Account", inverse_of: :inventory_items_provided  
  belongs_to :membership, index: true, optional: true
  belongs_to :team, index: true
    
  validates_presence_of :name, :group, :account, :membership
      
  before_validation do
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :circle => group, :type => 'created_inventory_item'
    end
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :account_id => :lookup,
      :responsible_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :team_id => :lookup
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :name => 'Item name'
    }[attr.to_sym] || super  
  end   
      
end
