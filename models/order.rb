class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  field :value, type: Integer
  field :session_id, type: String
  field :payment_intent, type: String
  field :payment_completed, type: Boolean

  belongs_to :event, optional: true
  belongs_to :account, optional: true

  has_many :tickets, dependent: :destroy
  has_many :donations, dependent: :destroy

  def self.admin_fields
    {
      value: :number,
      session_id: :text,
      payment_intent: :text,
      payment_completed: :check_box,
      event_id: :lookup,
      account_id: :lookup,
      tickets: :collection,
      donations: :collection
    }
  end

  def self.incomplete
    where(:payment_intent.ne => nil).where(:payment_completed.ne => true)
  end

  def incomplete?
    payment_intent && !payment_completed
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
    if event.activity && event.activity.privacy == 'open'
      event.activity.activityships.create account: account      
    end   
  end
  
  after_destroy do
    if event.organisation and value > 0 and payment_completed?
      Stripe.api_key = event.organisation.stripe_sk
      pi = Stripe::PaymentIntent.retrieve payment_intent      
      Stripe::Refund.create(charge: pi.charges.first.id, reverse_transfer: (event.revenue_sharer_organisationship ? true : false))
    end
  end  
  
  def send_tickets
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
    batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
               
    order = self
    event = order.event
    account = order.account
    content = ERB.new(File.read(Padrino.root('app/views/emails/tickets.erb'))).result(binding)
    batch_message.from ENV['NOTIFICATION_EMAIL']
    batch_message.subject "Thanks for booking #{event.name} via Autopia"
    batch_message.body_html ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
                
    [account].each { |account|
      batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id})
    }
        
    batch_message.finalize      
  end
  
end
