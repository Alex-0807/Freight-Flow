class RateCard < ApplicationRecord
  # Always loaded lightest tier first, which is the order pricing needs.
  has_many :rate_rules, -> { order(:min_weight_kg) }, dependent: :destroy, inverse_of: :rate_card
  has_many :customers, dependent: :restrict_with_exception
  has_many :consignments, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :base_charge, :minimum_charge, :fuel_levy_percent,
    presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cubic_conversion_factor, numericality: { only_integer: true, greater_than: 0 }
  # Only checked when this card claims to be the default; the partial unique index backs it up.
  validates :is_default, uniqueness: true, if: :is_default?

  def self.default_card
    find_by(is_default: true)
  end
end
