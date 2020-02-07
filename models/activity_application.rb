class ActivityApplication 
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :activity
  belongs_to :account, class_name: "Account", inverse_of: :activity_applications, index: true
  belongs_to :statused_by, class_name: "Account", inverse_of: :statused_activity_applications, index: true, optional: true
   
  field :answers, :type => Array    
  field :status, :type => String  
  field :statused_at, :type => Time    
  
  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_reactions, :as => :commentable, :dependent => :destroy    
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end  
          
  def self.admin_fields
    {     
      :account_id => :lookup,                   
      :status => :select,
      :statused_at => :datetime,  
      :answers => :text_area
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {               
    }[attr.to_sym] || super  
  end    
    
  after_save do
    if status == 'Accepted'
      activity.activityships.create account: account
    end
  end  
  
  def self.statuses; ['Pending', 'To interview', 'On hold', 'Accepted', 'Rejected, to contact', 'Rejected, contacted']; end  
  def self.outstanding; where(:status.ne => 'Rejected'); end
  def self.pending; where(status: 'Pending'); end
  def self.interview_arranged; where(status: 'Interview arranged'); end
  def self.accepted; where(status: 'Accepted'); end
  def accepted?; status == 'Accepted'; end
  def self.rejected; where(status: 'Rejected'); end    
  def rejected?; status == 'Rejected'; end
  
  def subscribers
    activity.admins
  end
     
end