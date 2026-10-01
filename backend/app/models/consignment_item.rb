class ConsignmentItem < ApplicationRecord
  CUBIC_CM_PER_M3 = 1_000_000

  belongs_to :consignment

  validates :description, presence: true
  validates :quantity, :length_cm, :width_cm, :height_cm,
    numericality: { only_integer: true, greater_than: 0 }
  validates :weight_kg, numericality: { greater_than: 0 } # per unit

  # Weight of the whole line: 2 pallets x 180 kg = 360 kg.
  def line_weight_kg
    weight_kg * quantity
  end

  # Volume of the whole line in m3: 120 x 120 x 100 cm x 2 = 2.88 m3.
  # BigDecimal keeps the division exact (integer / integer would round down to 0).
  def line_volume_m3
    BigDecimal(length_cm * width_cm * height_cm * quantity) / CUBIC_CM_PER_M3
  end
end
