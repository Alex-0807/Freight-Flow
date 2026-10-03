require "rails_helper"

RSpec.describe Pricing::Measurements do
  it "adds up items, counting quantity for weight, volume and item count" do
    items = [
      build(:consignment_item, quantity: 2, weight_kg: 180, length_cm: 120, width_cm: 120, height_cm: 100),
      build(:consignment_item, quantity: 3, weight_kg: 12, length_cm: 40, width_cm: 30, height_cm: 30)
    ]

    totals = described_class.from_items(items)

    expect(totals.total_items).to eq(5)
    expect(totals.weight_kg).to eq(BigDecimal("396"))     # 2 x 180 + 3 x 12
    expect(totals.volume_m3).to eq(BigDecimal("2.988"))   # 2.88 + 3 x 0.036
  end

  it "rounds volume to 3 decimals (litres)" do
    item = build(:consignment_item, quantity: 1, length_cm: 11, width_cm: 11, height_cm: 11) # 0.001331 m3

    expect(described_class.from_items([ item ]).volume_m3).to eq(BigDecimal("0.001"))
  end
end
