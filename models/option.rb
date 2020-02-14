class Option
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :name, :type => String  
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  field :split_cost, :type => Boolean
  field :type, :type => String
  field :by_invitation, :type => Boolean
  
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :cost
  
  has_many :optionships, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'created_option'
  end      
  
  def circle
    gathering
  end
  
  def members
    Account.where(:id.in => optionship.pluck(:account_id))
  end  
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :capacity => :number,
      :cost => :number,
      :split_cost => :check_box,
      :type => :text,
      :gathering_id => :lookup,
      :account_id => :lookup,
      :optionships => :collection,
      :by_invitation => :check_box
    }
  end
  
  def self.types
    %w{Ticket Accommodation Transport}
  end
  
  def self.icon(type)
    case type
    when 'Ticket'
      'fa-ticket'
    when 'Accommodation'
      'fa-home'
    when 'Transport'
      'fa-bus'
    end
  end
  
  def icon
    Option.icon(type)
  end
  
  def cost_per_person
    if split_cost
      if optionships.count > 0
        (cost.to_f / optionships.count).round
      end
    else
      cost
    end
  end
  
  def full?
    capacity && optionships.count == capacity
  end
  
  after_save do
    optionships.each { |optionship| optionship.membership.update_requested_contribution }
  end    
  
  def self.human_attribute_name(attr, options={})  
    {
      :split_cost => 'Split cost between participants'
    }[attr.to_sym] || super  
  end   
    
end
