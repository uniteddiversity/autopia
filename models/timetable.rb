class Timetable
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :description, :type => String
  field :hide_schedule, :type => Boolean
 
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :spaces, :dependent => :destroy
  has_many :tslots, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_timetable'
  end        
   
  def self.admin_fields
    {
      :name => :text,
      :description => :wysiwyg,
      :hide_schedule => :check_box,
      :group_id => :lookup,
      :account_id => :lookup,
      :spaces => :collection,
      :tslots => :collection,
      :activities => :collection
    }
  end
    
end
