class WishlistItem
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
     
  belongs_to :wishlist, index: true
  belongs_to :group, index: true
  belongs_to :account, index: true, optional: true, class_name: "Account", inverse_of: :wishlist_items_listed
  belongs_to :provided_by, index: true, optional: true, class_name: "Account", inverse_of: :wishlist_items_provided  
  belongs_to :membership, index: true, optional: true
      
  before_validation do
    self.group = self.wishlist.group if self.wishlist
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :group => group, :type => 'created_wishlist_item'
    end
  end  
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :provided_by_id => :lookup,
      :wishlist_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup
    }
  end
      
end
