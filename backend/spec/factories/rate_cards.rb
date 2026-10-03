FactoryBot.define do
  factory :rate_card do
    sequence(:name) { |n| "Rate card #{n}" }
    base_charge { "25.00" }
    minimum_charge { "45.00" }
    fuel_levy_percent { "18.50" }
    cubic_conversion_factor { 250 }

    # The tiers from docs/architecture.md: 0 kg @ 0.55, 100 kg @ 0.42, 500 kg @ 0.35.
    # Built in memory, so build(:rate_card, :with_standard_tiers) needs no database,
    # and create(...) saves the tiers along with the card.
    trait :with_standard_tiers do
      after(:build) do |card|
        card.rate_rules.build(min_weight_kg: 0, per_kg_rate: "0.5500")
        card.rate_rules.build(min_weight_kg: 100, per_kg_rate: "0.4200")
        card.rate_rules.build(min_weight_kg: 500, per_kg_rate: "0.3500")
      end
    end
  end
end
