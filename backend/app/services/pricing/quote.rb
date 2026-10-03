module Pricing
  # The result of pricing a shipment: every number needed to explain the price,
  # not just the total. Immutable (Data), so nothing can change it after calculation.
  Quote = Data.define(
    :dead_weight_kg,       # what the scale says
    :volume_m3,
    :cubic_weight_kg,      # volume x cubic conversion factor
    :chargeable_weight_kg, # the greater of the two, rounded up to a whole kg
    :per_kg_rate,          # from the matching weight tier
    :freight_charge,       # base + weight charge, never below the minimum
    :fuel_levy_percent,
    :fuel_levy_amount,
    :total_charge
  )
end
