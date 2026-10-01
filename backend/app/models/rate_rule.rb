# One weight tier on a rate card: "from min_weight_kg upwards, charge per_kg_rate per kg".
# A tier applies until the next tier's min_weight_kg.
class RateRule < ApplicationRecord
  belongs_to :rate_card

  validates :min_weight_kg, presence: true,
    numericality: { greater_than_or_equal_to: 0 },
    uniqueness: { scope: :rate_card_id }
  validates :per_kg_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
