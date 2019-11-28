class Organisationcrown
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :organisation, index: true

  validates_uniqueness_of :account, scope: :organisation

  def self.admin_fields
    {     
      account_id: :lookup,
      organisation_id: :lookup
    }
  end
end
