class ProofOfDelivery < ApplicationRecord
  # Phones' clocks drift; allow a few minutes before calling a time "in the future".
  CLOCK_SKEW_ALLOWANCE = 5.minutes

  belongs_to :consignment

  validates :receiver_name, presence: true
  validates :delivered_at, presence: true
  validates :consignment_id, uniqueness: true
  validate :delivered_at_not_in_future

  private

  def delivered_at_not_in_future
    return if delivered_at.blank?

    errors.add(:delivered_at, "can't be in the future") if delivered_at > CLOCK_SKEW_ALLOWANCE.from_now
  end
end
