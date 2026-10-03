class Consignment < ApplicationRecord
  STATUSES = %w[booked allocated picked_up in_transit delivered].freeze
  AU_STATES = %w[ACT NSW NT QLD SA TAS VIC WA].freeze

  belongs_to :customer
  # Set by pricing, never by user input. optional: true keeps validation errors about
  # what the user sent; the NOT NULL column still guarantees every saved row has one.
  belongs_to :rate_card, optional: true
  belongs_to :driver, optional: true # nil until allocated

  # autosave + index_errors: an invalid item's own errors are copied onto the consignment as
  # "consignment_items[1].weight_kg", so the client knows which item and which field.
  # (Without autosave, Rails only reports a vague "consignment_items is invalid".)
  has_many :consignment_items, dependent: :destroy, inverse_of: :consignment,
    autosave: true, index_errors: true
  has_many :tracking_events, -> { order(:occurred_at, :id) },
    dependent: :restrict_with_exception, inverse_of: :consignment
  has_one :proof_of_delivery, dependent: :restrict_with_exception
  has_one :invoice, dependent: :restrict_with_exception

  # Gives consignment.delivered?, Consignment.in_transit (scope), etc.
  # Status only changes through the consignment services (Step 4), never via
  # enum bang methods like delivered!, which would skip the transition rules.
  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :reference, presence: true, uniqueness: { scope: :customer_id }
  validates :pickup_address_line1, :pickup_suburb, :pickup_state, :pickup_postcode,
    :delivery_address_line1, :delivery_suburb, :delivery_state, :delivery_postcode,
    presence: true
  validates :pickup_state, :delivery_state, inclusion: { in: AU_STATES }, allow_blank: true
  validates :pickup_postcode, :delivery_postcode, format: { with: /\A\d{4}\z/ }, allow_blank: true
  validates :requested_delivery_date, presence: true

  # Totals and price are computed by Consignments::Create, not typed by users.
  # allow_nil: if pricing was skipped because the input was invalid, the client sees the
  # real problem (e.g. a bad item) rather than "Freight charge is not a number".
  # NOT NULL and CHECK constraints in the database still guarantee saved rows are complete.
  validates :total_items, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :total_weight_kg, :chargeable_weight_kg, numericality: { greater_than: 0 }, allow_nil: true
  validates :total_volume_m3, :freight_charge, :fuel_levy_percent, :fuel_levy_amount, :total_charge,
    numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Rules that depend on "now" or on other tables live only here, not in the database.
  validate :requested_delivery_date_not_in_past, on: :create
  validate :must_have_items, on: :create
  # Safety net: even code that skips the services (e.g. consignment.delivered!) can't
  # save a status change the lifecycle doesn't allow.
  validate :status_change_follows_flow, on: :update, if: :will_save_change_to_status?

  # Appends a tracking event stamped with the consignment's *current* status.
  # Called by the consignment services inside their transaction.
  def record_event!(event_type:, actor:, occurred_at: Time.current, latitude: nil, longitude: nil, metadata: {})
    tracking_events.create!(
      event_type: event_type, status: status, user: actor, occurred_at: occurred_at,
      latitude: latitude, longitude: longitude, metadata: metadata
    )
  end

  private

  def status_change_follows_flow
    return if StatusFlow.allowed?(status_in_database, status)

    errors.add(:status, "can't change from #{status_in_database} to #{status}")
  end

  def requested_delivery_date_not_in_past
    return if requested_delivery_date.blank?

    # Date.current uses config.time_zone (Melbourne), not the server's clock zone.
    errors.add(:requested_delivery_date, "can't be in the past") if requested_delivery_date < Date.current
  end

  def must_have_items
    errors.add(:consignment_items, "must include at least one item") if consignment_items.empty?
  end
end
