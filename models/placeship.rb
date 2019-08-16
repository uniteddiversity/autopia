class Placeship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :unsubscribed, type: Boolean

  belongs_to :account, index: true
  belongs_to :place, index: true
  belongs_to :placeship_category, optional: true, index: true

  validates_uniqueness_of :account, scope: :place

  def self.admin_fields
    {
      unsubscribed: :check_box,
      account_id: :lookup,
      place_id: :lookup,
      placeship_category_id: :lookup
    }
  end
end
