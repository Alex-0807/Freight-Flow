FactoryBot.define do
  # A valid, priced consignment: the "2 pallets" example from docs/architecture.md.
  # Traits create it directly in a later status, a shortcut for tests only.
  # Real code always moves status through the Consignments services.
  factory :consignment do
    customer
    rate_card
    sequence(:reference) { |n| "PO-#{1000 + n}" }

    pickup_address_line1 { "1 Dock Road" }
    pickup_suburb { "Port Melbourne" }
    pickup_state { "VIC" }
    pickup_postcode { "3207" }
    delivery_address_line1 { "9 Main Street" }
    delivery_suburb { "Geelong" }
    delivery_state { "VIC" }
    delivery_postcode { "3220" }
    requested_delivery_date { Date.current + 1 }

    total_items { 2 }
    total_weight_kg { "360.000" }
    total_volume_m3 { "2.880" }
    chargeable_weight_kg { "720.000" }
    freight_charge { "277.00" }
    fuel_levy_percent { "18.50" }
    fuel_levy_amount { "51.25" }
    total_charge { "328.25" }

    # A consignment must have at least one item to be created.
    after(:build) do |consignment|
      if consignment.consignment_items.empty?
        consignment.consignment_items.build(FactoryBot.attributes_for(:consignment_item))
      end
    end

    trait :allocated do
      status { "allocated" }
      driver
    end

    trait :picked_up do
      status { "picked_up" }
      driver
    end

    trait :in_transit do
      status { "in_transit" }
      driver
    end

    trait :delivered do
      status { "delivered" }
      driver
    end
  end
end
