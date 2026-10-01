FactoryBot.define do
  factory :rate_card do
    sequence(:name) { |n| "Rate card #{n}" }
    base_charge { "25.00" }
    minimum_charge { "45.00" }
    fuel_levy_percent { "18.50" }
    cubic_conversion_factor { 250 }
  end
end
