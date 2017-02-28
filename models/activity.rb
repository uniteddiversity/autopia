class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :space, index: true
  belongs_to :tslot, index: true
  belongs_to :timetable, index: true
  belongs_to :account, class_name: "Account", inverse_of: :activities, index: true
  belongs_to :scheduled_by, class_name: "Account", inverse_of: :activities_scheduled, index: true
  belongs_to :group, index: true
  
  before_validation do
    self.timetable = self.space.timetable if self.space
    self.group = self.timetable.group if self.timetable
  end    
  
  field :name, :type => String
  field :description, :type => String
  field :image_uid, :type => String
  
  dragonfly_accessor :image
  
  validates_presence_of :name, :description, :account, :timetable, :group
  
  has_many :attendances, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => timetable.group, :type => 'listed_activity'
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :image => :image,
      :account_id => :lookup,
      :space_id => :lookup,
      :tslot_id => :lookup,    
      :timetable_id => :lookup      
    }
  end
        
end
