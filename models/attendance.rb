class Attendance
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :activity
  belongs_to :account
  
  validates_presence_of :activity, :account
  validates_uniqueness_of :activity, :scope => :account
        
  def self.admin_fields
    {
      :activity_id => :lookup,
      :account_id => :lookup,
    }
  end
    
end
