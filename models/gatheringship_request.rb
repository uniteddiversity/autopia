class GatheringshipRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :gathering
          
  has_many :gatheringship_request_votes, :dependent => :destroy
  
  def self.admin_fields
    {
      :account_id => :lookup,
      :gathering_id => :lookup
    }
  end
    
end
