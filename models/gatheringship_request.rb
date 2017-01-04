class GatheringshipRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :status, :type => String
  field :answers, :type => Array  

  belongs_to :gathering             
  belongs_to :account, index: true, class_name: "Account", inverse_of: :gatheringship_requests
  belongs_to :processed_by, index: true, class_name: "Account", inverse_of: :gatheringship_requests_processed
  
  has_many :gatheringship_request_votes, :dependent => :destroy
  has_many :gatheringship_request_blocks, :dependent => :destroy  
  
  validates_presence_of :account, :gathering, :status
  validates_uniqueness_of :account, :scope => :gathering  
      
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
