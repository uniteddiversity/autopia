class Transport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  field :outbound_departure_time, :type => Time
  field :return_departure_time, :type => Time
  
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :cost
  
  before_validation do
    self.cost = 0 if !self.cost
  end
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'created_transport'
  end      
  
  def circle
    gathering
  end
  
  has_many :transportships, :dependent => :destroy
  
  def members
    Account.where(:id.in => transportships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area, 
      :outbound_departure_time => :datetime,
      :return_departure_time => :datetime,
      :capacity => :number,
      :cost => :number,
      :gathering_id => :lookup,
      :account_id => :lookup,
      :transportships => :collection,
    }
  end
  
  def full?
    capacity && transportships.count == capacity
  end
  
  after_save do
    transportships.each { |transportship| transportship.membership.update_requested_contribution }
  end
    
end
