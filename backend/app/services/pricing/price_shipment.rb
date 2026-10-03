module Pricing
  # Connects the pricing building blocks in order:
  #
  #   1. Measurements      add up the items          -> 360 kg, 2.880 m3
  #   2. RateCardResolver  pick the customer's card  -> "Standard"
  #   3. FreightCalculator price it                  -> 277.00 + 51.25 = 328.25
  #
  # Used by booking (Consignments::Create saves the result) and by the quote endpoint
  # (only shows it). Saves nothing itself.
  class PriceShipment
    Result = Data.define(:measurements, :rate_card, :quote)

    def self.call(customer:, items:)
      measurements = Measurements.from_items(items)
      rate_card = RateCardResolver.call(customer)
      quote = FreightCalculator.call(
        rate_card: rate_card, weight_kg: measurements.weight_kg, volume_m3: measurements.volume_m3
      )

      Result.new(measurements: measurements, rate_card: rate_card, quote: quote)
    end
  end
end
