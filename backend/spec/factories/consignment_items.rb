FactoryBot.define do
  factory :consignment_item do
    consignment
    description { "Pallet - office chairs" }
    quantity { 2 }
    weight_kg { "180.000" } # per unit
    length_cm { 120 }
    width_cm { 120 }
    height_cm { 100 }
  end
end
