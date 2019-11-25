class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  extend Dragonfly::Model

  field :name, type: String
  field :start_time, type: Time
  field :end_time, type: Time
  field :location, type: String
  field :coordinates, type: Array
  field :image_uid, type: String
  field :description, type: String
  field :email, type: String
  field :facebook_event_id, type: String
  field :feedback_questions, type: String
  field :suggested_donation, type: Float
  field :capacity, type: Integer
  field :facilitator_revenue_share, type: Float

  def self.marker_color
    'red'
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

  belongs_to :account, inverse_of: :events, index: true
  belongs_to :facilitator, class_name: "Account", inverse_of: :events_facilitating, index: true, optional: true
  belongs_to :promoter, index: true, optional: true
  belongs_to :activity, optional: true, index: true
  
  has_many :ticket_types, dependent: :destroy
  accepts_nested_attributes_for :ticket_types, allow_destroy: true, reject_if: :all_blank

  has_many :tickets, dependent: :destroy
  has_many :donations, dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :waitships, dependent: :destroy
  has_many :event_feedbacks, dependent: :destroy

  def summary
    start_time ? "#{name} (#{start_time.to_date})" : name
  end

  dragonfly_accessor :image

  def feedback_questions_a
    q = (feedback_questions || '').split("\n").map(&:strip).reject(&:blank?)
    q.empty? ? [] : q
  end

  before_validation :ensure_end_after_start
  def ensure_end_after_start
    errors.add(:end_time, 'must be after the start time') unless end_time >= start_time
  end

  validates_presence_of :name, :start_time, :end_time, :location

  def self.admin_fields
    {
      summary: { type: :text, index: false, edit: false },
      name: { type: :text, full: true },
      start_time: :datetime,
      end_time: :datetime,
      location: :text,
      image: :image,
      description: :wysiwyg,
      email: :email,
      facebook_event_id: :number,
      facilitator_revenue_share: :number,
      feedback_questions: :text_area,
      suggested_donation: :number,
      capacity: :number,
      account_id: :lookup,
      promoter_id: :lookup,
      ticket_types: :collection
    }
  end

  def future?(from = Date.today)
    start_time >= from
  end

  def self.future(from = Date.today)
    where(:start_time.gte => from).order('start_time asc')
  end

  def past?(from = Date.today)
    start_time < from
  end

  def self.past(from = Date.today)
    where(:start_time.lt => from).order('start_time desc')
  end

  def when_details
    if start_time && end_time
      if start_time.to_date == end_time.to_date
        "#{start_time.to_date}, #{start_time.to_s(:no_double_zeros)} – #{end_time.to_s(:no_double_zeros)}"
      else
        "#{start_time.to_date}, #{start_time.to_s(:no_double_zeros)} – #{end_time.to_date}, #{end_time.to_s(:no_double_zeros)}"
      end
    end
  end

  def self.human_attribute_name(attr, options = {})
    {
      name: 'Event title',
      email: 'Contact email',
      facebook_event_id: 'Facebook event ID'
    }[attr.to_sym] || super
  end

  def sold_out?
    ticket_types.count > 0 && ticket_types.where(:hidden.ne => true).all? { |ticket_type| ticket_type.number_of_tickets_available_in_single_purchase == 0 }
  end

  def tickets_available?
    ticket_types.count > 0 && ticket_types.where(:hidden.ne => true).any? { |ticket_type| ticket_type.number_of_tickets_available_in_single_purchase > 0 }
  end

  def tickets_counting_towards_capacity
    tickets.where(:ticket_type_id.in => ticket_types_counting_towards_capacity.pluck(:id))
  end

  def ticket_types_counting_towards_capacity
    ticket_types.where(:exclude_from_capacity.ne => true)
  end

  def places_remaining
    if capacity
      capacity - tickets_counting_towards_capacity.count
    end
  end
  
  def average_rating
    ratings = event_feedbacks.where(:rating.ne => nil).pluck(:rating)
    if ratings.length > 0
      ratings = ratings.map(&:to_i)
      (ratings.inject(:+).to_f / ratings.length).round(1)
    end
  end
  
  def attendees
    Account.where(:id.in => tickets.pluck(:account_id))
  end  
  
end
