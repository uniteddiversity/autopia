class Attendance
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :activity, index: true
  belongs_to :account, index: true
  
  validates_presence_of :activity, :account
  validates_uniqueness_of :activity, :scope => :account
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => activity.group, :type => 'interested_in_activity'
  end      
        
  def self.admin_fields
    {
      :activity_id => :lookup,
      :account_id => :lookup,
    }
  end
    
end
