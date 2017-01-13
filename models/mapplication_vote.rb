class MapplicationVote
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :mapplication
  
  validates_presence_of :account, :mapplication
  validates_uniqueness_of :account, :scope => :mapplication
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :mapplication_id => :lookup
    }
  end
    
end
