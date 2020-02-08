class Transport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  field :split_cost, :type => Boolean
  field :outbound_departure_time, :type => Time
  field :return_departure_time, :type => Time  
  
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :cost
  
  has_many :transportships, :dependent => :destroy
    
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'created_transport'
  end      
  
  def circle
    gathering
  end
  
  def members
    Account.where(:id.in => transportships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area, 
      :capacity => :number,
      :cost => :number,
      :split_cost => :check_box,
      :gathering_id => :lookup,
      :account_id => :lookup,
      :transportships => :collection,
      :outbound_departure_time => :datetime,
      :return_departure_time => :datetime,      
    }
  end
  
  def cost_per_person
    if split_cost
      if transportships.count > 0
        (cost.to_f / transportships.count).round
      end
    else
      cost
    end
  end   
  
  def full?
    capacity && transportships.count == capacity
  end
  
  after_save do
    transportships.each { |transportship| transportship.membership.update_requested_contribution }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :split_cost => 'Split cost between participants'
    }[attr.to_sym] || super  
  end    
  
  before_validation do
    self.cost = 0 if !self.cost
  end
  
end
