class RoomPeriod
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
 
  field :start_date, :type => Date
  field :end_date, :type => Date
  field :price, :type => Integer
  field :currency, :type => String
    
  belongs_to :room, index: true  
  belongs_to :account, index: true  

  validates_presence_of :start_date, :end_date, :price, :currency
          
  def self.admin_fields
    {     
      :start_date => :date,
      :end_date => :date,
      :price => :number,
      :currency => :select,
      :room_id => :lookup
    }
  end

  def self.currencies
    %w{GBP EUR USD SEK DKK}
  end
  
  def currency_symbol
    Gathering.currency_symbol(currency)
  end  
  
  def self.human_attribute_name(attr, options={})  
    {
      :price => 'Price per night',
    }[attr.to_sym] || super  
  end  
    
end
