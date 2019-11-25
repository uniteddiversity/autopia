class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  field :value, type: Float
  field :stripe_id, type: String
  field :payment_completed, type: Boolean

  belongs_to :event, optional: true
  belongs_to :account, optional: true

  has_many :tickets, dependent: :destroy
  has_many :donations, dependent: :destroy

  def self.admin_fields
    {
      value: :number,
      stripe_id: :text,
      payment_completed: :check_box,
      event_id: :lookup,
      account_id: :lookup,
      tickets: :collection,
      donations: :collection
    }
  end

  def self.incomplete
    where(:stripe_id.ne => nil).where(:payment_completed.ne => true)
  end

  def incomplete?
    stripe_id && !payment_completed
  end

  def description
    descriptions = []
    TicketType.where(:id.in => tickets.pluck(:ticket_type_id)).each do |ticket_type|
      descriptions << "#{ticket_type.name} ticket x#{tickets.where(ticket_type: ticket_type).count}"
    end

    donations.each do |donation|
      descriptions << "£#{donation.amount} donation"
    end

    "#{event.name}, #{event.when_details} at #{event.location}: #{descriptions.join(', ')}"
  end
  
  after_create do
    if event.activity
      event.activity.activityships.create account: account      
    end   
  end
  
end
