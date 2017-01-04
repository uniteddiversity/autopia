class GatheringshipRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :gathering
          
  has_many :gatheringship_request_votes, :dependent => :destroy
  has_many :gatheringship_request_blocks, :dependent => :destroy
    
  belongs_to :account, index: true, class_name: "Account", inverse_of: :gatheringship_requests
  belongs_to :processed_by, index: true, class_name: "Account", inverse_of: :gatheringship_requests_processed
  
  validates_presence_of :account, :gathering, :status
  
  field :status, :type => String
  field :answers, :type => Array
  
  def self.pending
    where(status: 'pending')
  end
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end
        
  def self.admin_fields
    {
      :summary => {:type => :text, :index => false, :edit => false},
      :account_id => :lookup,
      :gathering_id => :lookup,
      :status => :select,
      :answers => :text_area
    }
  end
  
  def summary
    "#{self.account.name} - #{self.gathering.name}"
  end
    
  def self.statuses
    ['pending', 'accepted', 'rejected']
  end    

end
