# An append-only history entry. Rows are inserted, never updated or deleted:
# a correction is a new event.
class TrackingEvent < ApplicationRecord
  EVENT_TYPES = %w[status_changed driver_reassigned].freeze
  # occurred_at comes from the driver's phone, whose clock may run slightly fast.
  CLOCK_SKEW_ALLOWANCE = 5.minutes

  belongs_to :consignment
  belongs_to :user, optional: true # nil for system-generated events

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :status, inclusion: { in: Consignment::STATUSES }
  validates :occurred_at, presence: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :coordinates_come_in_pairs
  validate :occurred_at_not_in_future

  # Once saved, the record is read-only: update or destroy raises
  # ActiveRecord::ReadOnlyRecord.
  def readonly?
    persisted? || super
  end

  private

  def coordinates_come_in_pairs
    return if latitude.nil? == longitude.nil?

    errors.add(:base, "latitude and longitude must be given together")
  end

  def occurred_at_not_in_future
    return if occurred_at.blank?

    errors.add(:occurred_at, "can't be in the future") if occurred_at > CLOCK_SKEW_ALLOWANCE.from_now
  end
end
