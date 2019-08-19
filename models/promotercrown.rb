class Promotercrown
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :promoter, index: true

  validates_uniqueness_of :account, scope: :promoter

  def self.admin_fields
    {     
      account_id: :lookup,
      promoter_id: :lookup
    }
  end
end
