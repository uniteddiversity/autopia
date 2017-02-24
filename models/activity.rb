class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :space
  belongs_to :tslot
  belongs_to :group
  belongs_to :account, class_name: "Account", inverse_of: :activities
  belongs_to :scheduled_by, class_name: "Account", inverse_of: :activities_scheduled
  
  field :name, :type => String
  field :description, :type => String
  field :image_uid, :type => String
  
  dragonfly_accessor :image
  
  validates_presence_of :name, :description, :account, :group
  
  has_many :attendances, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'listed_activity'
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :image => :image,
      :account_id => :lookup,
      :space_id => :lookup,
      :tslot_id => :lookup,    
      :group_id => :lookup      
    }
  end
        
end
