class LocalGroupship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :unsubscribed, :type => Boolean
  field :admin, :type => Boolean
  
  def self.admin_fields
    {
      :account_id => :lookup,
      :local_group_id => :lookup,
      :unsubscribed => :check_box,
      :admin => :check_box
    }
  end  

  belongs_to :account
  belongs_to :local_group
  
  validates_uniqueness_of :account, :scope => :local_group
      
end
