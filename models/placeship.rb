class Placeship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :unsubscribed, type: Boolean
  field :stripe_connect_json, type: String

  belongs_to :account, index: true
  belongs_to :place, index: true
  belongs_to :placeship_category, optional: true, index: true

  validates_uniqueness_of :account, scope: :place

  def self.admin_fields
    {
      unsubscribed: :check_box,
      stripe_connect_json: :text_area,
      account_id: :lookup,
      place_id: :lookup,
      placeship_category_id: :lookup
    }
  end
end
