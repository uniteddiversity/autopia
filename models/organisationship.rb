class Organisationship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :stripe_connect_json, type: String
  field :admin, type: Boolean
  field :unsubscribed, type: Boolean
      
  belongs_to :account, index: true
  belongs_to :organisation, index: true

  def stripe_user_id
    JSON.parse(stripe_connect_json)['stripe_user_id']
  end

  validates_uniqueness_of :account, scope: :organisation

  def self.admin_fields
    {
      admin: :check_box,
      unsubscribed: :check_box,
      stripe_connect_json: :text_area,
      account_id: :lookup,
      organisation_id: :lookup
    }
  end
  
  def self.protected_attributes
    %w[admin]
  end
  
end
