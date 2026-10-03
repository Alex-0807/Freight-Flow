class QuoteSerializer < BaseSerializer
  # Takes a Pricing::PriceShipment::Result.
  def self.call(priced)
    quote = priced.quote
    {
      rate_card: { id: priced.rate_card.id, name: priced.rate_card.name },
      total_items: priced.measurements.total_items,
      dead_weight_kg: decimal(quote.dead_weight_kg, 3),
      volume_m3: decimal(quote.volume_m3, 3),
      cubic_weight_kg: decimal(quote.cubic_weight_kg, 3),
      chargeable_weight_kg: decimal(quote.chargeable_weight_kg, 3),
      per_kg_rate: decimal(quote.per_kg_rate, 4),
      freight_charge: money(quote.freight_charge),
      fuel_levy_percent: decimal(quote.fuel_levy_percent, 2),
      fuel_levy_amount: money(quote.fuel_levy_amount),
      total_charge: money(quote.total_charge)
    }
  end
end
