class Promoter
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

  validates_presence_of :name, :website, :stripe_client_id, :stripe_endpoint_secret, :stripe_pk, :stripe_sk

  belongs_to :account, index: true, optional: true

  has_many :events, dependent: :nullify
  has_many :activities, dependent: :destroy
  has_many :promoterships, dependent: :destroy
  has_many :promotercrowns, dependent: :destroy

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

  def team_members
    Account.where(:id.in => promotercrowns.pluck(:account_id))
  end  

  def clients
    Account.where(:id.in => promoterships.pluck(:account_id))
  end

  def self.admin_fields
    {
      name: :text,
      website: :url,
      image: :image,
      stripe_client_id: :text,
      stripe_endpoint_secret: :text,
      stripe_pk: :text,
      stripe_sk: :text
    }
  end

  def self.human_attribute_name(attr, options = {})
    {
      stripe_client_id: 'Stripe client ID',
      stripe_endpoint_secret: 'Stripe endpoint secret',
      stripe_pk: 'Stripe public key',
      stripe_sk: 'Stripe secret key',
    }[attr.to_sym] || super
  end
end
