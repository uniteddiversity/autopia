class Transport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :capacity, :type => Integer
  field :cost, :type => Integer
  field :outward_leaves_at, :type => DateTime
  field :return_leaves_at, :type => DateTime
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  validates_presence_of :name, :cost, :capacity
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_transport'
  end      
  
  has_many :transportships, :dependent => :destroy
  
  def members
    Account.where(:id.in => transportships.pluck(:account_id))
  end
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,      
      :capacity => :number,
      :cost => :number,
      :group_id => :lookup,
      :account_id => :lookup,
      :transportships => :collection,
    }
  end
  
  def full?
    transportships.count == capacity
  end
  
  after_save do
    transportships.each { |transportship| transportship.membership.update_requested_contribution }
  end
    
end
