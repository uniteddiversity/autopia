class Mapplication
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :status, :type => String
  field :answers, :type => Array  

  belongs_to :group, index: true
  belongs_to :account, class_name: "Account", inverse_of: :mapplications, index: true
  belongs_to :processed_by, class_name: "Account", inverse_of: :mapplications_processed, index: true, optional: true
  
  has_many :verdicts, :dependent => :destroy
  # has_one :membership, :dependent => :destroy
  
  validates_presence_of :status
  validates_uniqueness_of :account, :scope => :group  
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'applied'
  end    
      
  def self.pending
    where(status: 'pending')
  end
  
  def self.on_ice
    where(status: 'on_ice')
  end  
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end
  
  def acceptable?
    status != 'on_ice' and (!group.member_limit or (group.memberships.count < group.member_limit)) and verdicts.proposers.count > 0
  end
  
  def meets_threshold
    group.threshold and (verdicts.proposers.count + verdicts.supporters.count) >= group.threshold
  end
  
  def accept
    mapplication = self    
    account = mapplication.account
    group = mapplication.group    
    update_attribute(:status, 'accepted')
    group.memberships.create account: account, mapplication: mapplication                            
  end
        
  def self.admin_fields
    {
      :summary => {:type => :text, :index => false, :edit => false},
      :account_id => :lookup,
      :group_id => :lookup,
      :verdicts => :collection,
      :status => :select,
      :answers => :text_area
    }
  end
    
  def summary
    "#{self.account.name} - #{self.group.name}"
  end
    
  def self.statuses
    ['pending', 'accepted', 'on_ice']
  end    

end
