module Pricing
  # The physical totals of a shipment, added up from its items.
  #
  #   Pricing::Measurements.from_items(consignment.consignment_items)
  #   # => #<data total_items=2, weight_kg=360.0, volume_m3=2.88>
  #
  # Volume is rounded to 3 decimals (litres) *here*, once, so the price can always be
  # reproduced from the totals stored on the consignment.
  Measurements = Data.define(:total_items, :weight_kg, :volume_m3) do
    def self.from_items(items)
      new(
        total_items: items.sum(&:quantity),
        weight_kg: items.sum(BigDecimal("0"), &:line_weight_kg),
        volume_m3: items.sum(BigDecimal("0"), &:line_volume_m3).round(3, :half_up)
      )
    end
  end
end
