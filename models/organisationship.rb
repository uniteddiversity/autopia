class Organisationship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :stripe_connect_json, type: String
  field :admin, type: Boolean
  field :unsubscribed, type: Boolean
  field :monthly_donation_method, type: String
  field :monthly_donation_amount, type: Float
  field :monthly_donation_start_date, type: Date  
      
  belongs_to :account, index: true
  belongs_to :organisation, index: true

  def stripe_user_id
    JSON.parse(stripe_connect_json)['stripe_user_id']
  end

  validates_uniqueness_of :account, scope: :organisation

  def self.admin_fields
    {
      account_id: :lookup,
      organisation_id: :lookup,      
      admin: :check_box,
      unsubscribed: :check_box,
      stripe_connect_json: :text_area,
      monthly_donation_amount: :number,
      monthly_donation_method: :select,  
      monthly_donation_start_date: :date 
    }
  end
  
  def monthly_donor?
    monthly_donation_amount    
  end
  
  def self.protected_attributes
    %w[admin]
  end
  
  def self.monthly_donation_methods; [''] + %w{GoCardless Patreon PayPal}; end
  
end
