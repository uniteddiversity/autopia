class GatheringshipRequestVote
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :gatheringship_request
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :gatheringship_request_id => :lookup
    }
  end
    
end
