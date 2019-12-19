class TicketType
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :event

  has_many :tickets, :dependent => :nullify

  field :name, :type => String
  field :price, :type => Integer
  field :quantity, :type => Integer
  field :hidden, :type => Boolean
  field :exclude_from_capacity, :type => Boolean
  field :max_quantity_per_transaction, :type => Integer

  validates_presence_of :name, :price, :quantity

  def self.admin_fields
    {
      :name => :text,
      :price => :number,
      :quantity => :number,
      :hidden => :check_box,
      :exclude_from_capacity => :check_box,
      :max_quantity_per_transaction => :number,
      :event_id => :lookup,
      :tickets => :collection
    }
  end

  def remaining
    quantity - tickets.count
  end

  def number_of_tickets_available_in_single_purchase
    [remaining, exclude_from_capacity? ? nil : event.places_remaining, max_quantity_per_transaction || nil].compact.min
  end

end
