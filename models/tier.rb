class Tier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  
  belongs_to :gathering, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :cost
    
  has_many :tierships, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => circle, :type => 'created_tier'
  end      
  
  def circle
    gathering
  end
  
  def members
    Account.where(:id.in => tierships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :capacity => :number,
      :cost => :number,      
      :gathering_id => :lookup,
      :account_id => :lookup,
      :tierships => :collection,
    }
  end
  
  after_save do
    tierships.each { |tiership| tiership.membership.update_requested_contribution }
  end  
  
  def full?
    capacity && tierships.count == capacity
  end  
    
end
