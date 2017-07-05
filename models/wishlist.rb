class Wishlist
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name, :group
  
  has_many :wishlist_items, :dependent => :destroy
  
  attr_accessor :prevent_notifications
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    unless prevent_notifications
      notifications.create! :group => group, :type => 'created_wishlist'
    end
  end      
          
  def self.admin_fields
    {
      :name => :text,
      :description => :wysiwyg,
      :group_id => :lookup,
      :account_id => :lookup,
      :wishlist_items => :collection
    }
  end
    
end
