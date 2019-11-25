class ActivityFacilitation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :bio, :type => String
  field :featured, :type => Boolean
  
  def self.admin_fields
    {
      :bio => :wysiwyg,
      :featured => :check_box,
      :account_id => :lookup,
      :activity_id => :lookup
    }
  end  

  belongs_to :account
  belongs_to :activity
  
  validates_uniqueness_of :account, :scope => :activity
    
end
