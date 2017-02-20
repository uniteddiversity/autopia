class Tiership
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :tier
  belongs_to :group
  
  validates_presence_of :account, :tier
  validates_uniqueness_of :account, :scope => :group
           
  def self.admin_fields
    {
      :account_id => :lookup,
      :tier_id => :lookup
    }
  end
      
end
