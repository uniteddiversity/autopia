class Follow
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :follower, class_name: "Account", inverse_of: :follows_as_follower, index: true
  belongs_to :followee, class_name: "Account", inverse_of: :follows_as_followee, index: true
  
  validates_uniqueness_of :follower, :scope => :followee
    
  def self.admin_fields
    {
			:follower_id => :lookup,
      :followee_id => :lookup
    }
  end
  
  def self.mutual(a,b)
    Follow.find_by(follower: a, followee: b) && Follow.find_by(follower: b, followee: a)
  end
  
#  has_many :notifications, as: :notifiable, dependent: :destroy
#  after_create do
#    notifications.create! :circle => followee, :type => 'followed'    
#  end   
      
end
