class Activityship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :unsubscribed, :type => Boolean
  field :admin, :type => Boolean
  field :hide_membership, :type => Boolean
  
  def self.admin_fields
    {
      :account_id => :lookup,
      :activity_id => :lookup,
      :unsubscribed => :check_box,
      :hide_membership => :check_box,
      :admin => :check_box
    }
  end  

  belongs_to :account
  belongs_to :activity
  
  validates_uniqueness_of :account, :scope => :activity
  
  def self.protected_attributes
    %w[admin]
  end  
      
end
