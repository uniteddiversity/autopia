class Organisationship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :stripe_connect_json, type: String
  field :admin, type: Boolean
  field :unsubscribed, type: Boolean
  field :monthly_donation_method, type: String
  field :monthly_donation_amount, type: Float
  field :monthly_donation_start_date, type: Date  
  field :why_i_joined, type: String    
  field :why_i_joined_public, type: Boolean   
  field :why_i_joined_edited, type: String  
      
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
      monthly_donation_start_date: :date,
      why_i_joined: :text_area,
      why_i_joined_public: :check_box,
      why_i_joined_edited: :text_area
    }
  end
  
  def monthly_donor?
    monthly_donation_amount    
  end
  
  def organisation_tier
    organisation_tier = nil
    organisation.organisation_tiers.order('threshold asc').each { |ot|
      if monthly_donation_amount >= ot.threshold
        organisation_tier = ot
      end
    }
    organisation_tier    
  end
  
  def monthly_donor_discount
    organisation_tier.try(:discount) || 0
  end
  
  def self.protected_attributes
    %w[admin]
  end
  
  def self.monthly_donation_methods; [''] + %w{GoCardless Patreon PayPal}; end
  
end
