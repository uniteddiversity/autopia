class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model

  field :name, type: String
  field :name_transliterated, type: String
  field :location, type: String
  field :website, type: String
  field :coordinates, type: Array
  field :image_uid, type: String
  field :stripe_client_id, type: String
  field :stripe_endpoint_secret, type: String
  field :stripe_pk, type: String
  field :stripe_sk, type: String

  validates_presence_of :name, :location

  belongs_to :account, index: true, optional: true

  before_validation do
    self.name_transliterated = I18n.transliterate(name) if name
  end

  has_many :posts, as: :commentable, dependent: :destroy
  has_many :subscriptions, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comment_reactions, as: :commentable, dependent: :destroy
  has_many :events, inverse_of: :promoter, dependent: :nullify

  has_many :notifications_as_notifiable, as: :notifiable, dependent: :destroy, class_name: 'Notification', inverse_of: :notifiable
  has_many :notifications_as_circle, as: :circle, dependent: :destroy, class_name: 'Notification', inverse_of: :circle
  after_create do
    notifications_as_notifiable.create! circle: account, type: 'created_place'
  end

  has_many :placeships, dependent: :destroy

  def subscribers
    Account.where(:id.in => placeships.where(:unsubscribed.ne => true).pluck(:account_id))
  end

  def followers
    Account.where(:id.in => placeships.pluck(:account_id))
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

  def self.marker_color
    'red'
  end

  def self.admin_fields
    {
      name: :text,
      name_transliterated: { type: :text, disabled: true },
      website: :url,
      stripe_client_id: :text,
      stripe_endpoint_secret: :text,
      stripe_pk: :text,
      stripe_sk: :text
    }
  end
end
