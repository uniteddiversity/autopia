class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :gathering, index: true
  belongs_to :membership, index: true
  belongs_to :payment_attempt, index: true, optional: true

  field :gathering_name, type: String
  field :amount, type: Integer
  field :currency, type: String

  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! circle: gathering, type: 'created_payment'
  end

  validates_presence_of :gathering_name, :amount, :currency

  before_validation do
    if payment_attempt
      self.membership = payment_attempt.membership
      self.amount = payment_attempt.amount
      self.currency = payment_attempt.currency
    end
    self.account = membership.account if membership
    self.gathering = membership.gathering if membership
    self.gathering_name = gathering.name if gathering
  end

  after_create do
    membership.update_attribute(:paid, membership.paid + amount)
    gathering.update_attribute(:processed_via_stripe, gathering.processed_via_stripe + amount)
    gathering.update_attribute(:balance, gathering.balance + amount * (1 - ENV['AUTOPIA_CUT'].to_f))
  end

  def self.admin_fields
    {
      account_id: :lookup,
      gathering_id: :lookup,
      membership_id: :lookup,
      payment_attempt_id: :lookup,
      gathering_name: :text,
      currency: :text,
      amount: :number
    }
  end
end
