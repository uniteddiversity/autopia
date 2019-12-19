class Organisation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model

  field :name, type: String
  field :website, type: String
  field :image_uid, type: String
  field :stripe_client_id, type: String
  field :stripe_endpoint_secret, type: String
  field :stripe_pk, type: String
  field :stripe_sk, type: String
  field :gocardless_access_token, type: String
  field :patreon_api_key, type: String
  field :mailgun_api_key, type: String
  field :mailgun_domain, type: String
  field :location, type: String
  field :coordinates, type: Array
  field :monthly_donor_discount, type: Integer
  
  # Geocoder
  geocoded_by :location
  def lat
    coordinates[1] if coordinates
  end

  def lng
    coordinates[0] if coordinates
  end
  after_validation do
    geocode || (self.coordinates = nil)
  end

  validates_presence_of :name

  belongs_to :account, index: true

  has_many :events, dependent: :nullify
  has_many :activities, dependent: :destroy
  has_many :organisationships, dependent: :destroy
  has_many :pmails, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :local_groups, dependent: :destroy
  
  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy    
  
  def event_tags
    EventTag.where(:id.in => EventTagship.where(:event_id.in => events.pluck(:id)).pluck(:event_tag_id))
  end

  dragonfly_accessor :image
  before_validation do
    if image
      begin
        image.format
      rescue StandardError
        errors.add(:image, 'must be an image')
      end
    end
  end
  
  def subscribers
    subscribed_members
  end
  
  def members
    Account.where(:id.in => organisationships.pluck(:account_id))
  end    
  
  def subscribed_members
    Account.where(:id.in => organisationships.where(:unsubscribed.ne => true).pluck(:account_id))
  end
    
  def unsubscribed_members
    Account.where(:id.in => organisationships.where(:unsubscribed => true).pluck(:account_id))
  end 

  def admins
    Account.where(:id.in => organisationships.where(admin: true).pluck(:account_id))
  end  

  def revenue_sharers
    Account.where(:id.in => organisationships.where(:stripe_connect_json.ne => nil).pluck(:account_id))
  end
  
  def monthly_donors
    Account.where(:id.in => organisationships.where(:monthly_donation_method.ne => nil).pluck(:account_id))
  end
  

  def self.admin_fields
    {
      name: :text,
      website: :url,
      image: :image,
      stripe_client_id: :text,
      stripe_endpoint_secret: :text,
      stripe_pk: :text,
      stripe_sk: :text,
      gocardless_access_token: :text,
      patreon_api_key: :text,
      mailgun_api_key: :text,
      mailgun_domain: :text,
      monthly_donor_discount: :text
    }
  end

  def self.human_attribute_name(attr, options = {})
    {
      stripe_client_id: 'Stripe client ID',
      stripe_endpoint_secret: 'Stripe endpoint secret',
      stripe_pk: 'Stripe public key',
      stripe_sk: 'Stripe secret key',
      gocardless_access_token: 'GoCardless access token',
      patreon_api_key: 'Patreon API key',
      mailgun_api_key: 'Mailgun API key',
      mailgun_domain: 'Mailgun domain'
    }[attr.to_sym] || super
  end
  
  
  def sync_with_gocardless    
    organisationships.where(monthly_donation_method: 'GoCardless').set(monthly_donation_method: nil, monthly_donation_amount: nil, monthly_donation_start_date: nil)
    
    client = GoCardlessPro::Client.new(access_token: gocardless_access_token)

    list = client.subscriptions.list(params: {status: 'active'})
    subscriptions = list.records
    after = list.after
    while after
      list = client.subscriptions.list(params: {status: 'active', after: after})
      subscriptions += list.records
      after = list.after      
    end  
    
    subscriptions.each { |subscription|     
      
      mandate = client.mandates.get(subscription.links.mandate)
      customer = client.customers.get(mandate.links.customer)
        
      name = "#{customer.given_name} #{customer.family_name}"
      email = customer.email 
      amount = subscription.amount
      start_date = subscription.start_date
        
      puts "#{name} #{email} #{amount} #{start_date}"
      account = Account.find_by(email: /^#{::Regexp.escape(email)}$/i) || Account.create(name: name, email: email)
      organisationship = organisationships.find_by(account: account) || organisationships.create(account: account, unsubscribed: true)
        
      organisationship.monthly_donation_method = 'GoCardless'
      organisationship.monthly_donation_amount = amount.to_f/100
      organisationship.monthly_donation_start_date = start_date
      organisationship.save                
    }        
  end  
  
  
  def self.sync_with_patreon
    organisationships.where(monthly_donation_method: 'Patreon').set(monthly_donation_method: nil, monthly_donation_amount: nil, monthly_donation_start_date: nil)
    
    api_client = Patreon::API.new(patreon_api_key)

    # Get the campaign ID
    campaign_response = api_client.fetch_campaign
    campaign_id = campaign_response.data[0].id

    # Fetch all pledges
    all_pledges = []
    cursor = nil
    while true do
      page_response = api_client.fetch_page_of_pledges(campaign_id, {:count => 25, :cursor => cursor})
      all_pledges += page_response.data
      next_page_link = page_response.links[page_response.data]['next']
      if next_page_link
        parsed_query = CGI::parse(next_page_link)
        cursor = parsed_query['page[cursor]'][0]
      else
        break
      end
    end

    all_pledges.each { |pledge| 
      name = pledge.patron.full_name
      email = pledge.patron.email
      amount = pledge.amount_cents
      start_date = pledge.created_at
      
      puts "#{name} #{email} #{amount} #{start_date}"
      account = Account.find_by(email: /^#{::Regexp.escape(email)}$/i) || Account.create(name: name, email: email)
      organisationship = organisationships.find_by(account: account) || organisationships.create(account: account, unsubscribed: true)
        
      account.monthly_donation_method = 'Patreon'
      account.monthly_donation_amount = (amount.to_f*0.79)/100 # USD to GBP
      account.monthly_donation_start_date = start_date
      organisationship.save                 
    }    
  end  
  
end
