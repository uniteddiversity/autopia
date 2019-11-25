class Ticket
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :event
  belongs_to :account
  belongs_to :order, optional: true
  belongs_to :ticket_type, optional: true

  field :price, type: Float
  field :description, type: String

  attr_accessor :force

  before_validation do
    self.price = ticket_type.price if !price && ticket_type
  end

  def summary
    "#{event.name} : #{account.email} : #{description || ticket_type.try(:name)}"
  end

  def self.admin_fields
    {
      summary: { type: :text, edit: false },
      price: :number,
      description: :text,
      event_id: :lookup,
      account_id: :lookup,
      order_id: :lookup,
      ticket_type_id: :lookup
    }
  end

  before_validation do
    errors.add(:event, 'is in the past') if event && event.past? && !force
    errors.add(:ticket_type, 'is full') if ticket_type && (ticket_type.number_of_tickets_available_in_single_purchase == 0)
  end
  
  after_create do
    if event.activity
      event.activity.activityships.create account: account
    end
    # ticket might be destroyed again, so this should move
    event.waitships.find_by(account: account).try(:destroy)
  end  

end
