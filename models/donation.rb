class Donation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, :type => Float

  belongs_to :account, index: true
  belongs_to :event, index: true, optional: true
  belongs_to :order, index: true, optional: true

  validates_presence_of :amount

  def summary
    "#{account.name} : £#{amount}"
  end

  def self.admin_fields
    {
      :amount => :number,
      :account_id => :lookup,
      :event_id => :lookup,
      :order_id => :lookup
    }
  end
      
end
