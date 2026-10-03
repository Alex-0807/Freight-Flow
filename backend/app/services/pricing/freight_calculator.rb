module Pricing
  # Prices a shipment against a rate card. Pure calculation: no database writes, no side
  # effects, so booking (saves the price) and quoting (only shows it) share it.
  #
  #   Pricing::FreightCalculator.call(rate_card: card, weight_kg: 360, volume_m3: "2.880")
  #
  # The pricing rules (see docs/architecture.md section 7):
  #   cubic weight      = volume x cubic conversion factor (250 kg per m3)
  #   chargeable weight = the greater of dead and cubic weight, rounded UP to a whole kg
  #   freight           = base charge + chargeable weight x tier rate, never below the minimum
  #   fuel levy         = freight x levy %
  #   total             = freight + fuel levy
  # Money is rounded to cents (half-up) only at the end of each charge, never in between.
  class FreightCalculator
    def self.call(...) = new(...).call

    def initialize(rate_card:, weight_kg:, volume_m3:)
      @rate_card = rate_card
      # BigDecimal(value.to_s) accepts 360, "360.000" or BigDecimal("360") alike.
      @weight_kg = BigDecimal(weight_kg.to_s)
      @volume_m3 = BigDecimal(volume_m3.to_s)
    end

    def call
      # Item validations stop bad input long before this; these guard against misuse.
      raise ArgumentError, "weight must be greater than zero" unless @weight_kg.positive?
      raise ArgumentError, "volume can't be negative" if @volume_m3.negative?

      cubic_weight = @volume_m3 * @rate_card.cubic_conversion_factor
      chargeable_weight = [ @weight_kg, cubic_weight ].max.ceil
      rate = rate_rule_for(chargeable_weight).per_kg_rate

      freight = money([ @rate_card.base_charge + chargeable_weight * rate, @rate_card.minimum_charge ].max)
      fuel_levy = money(freight * @rate_card.fuel_levy_percent / 100)

      Quote.new(
        dead_weight_kg: @weight_kg,
        volume_m3: @volume_m3,
        cubic_weight_kg: cubic_weight,
        chargeable_weight_kg: BigDecimal(chargeable_weight),
        per_kg_rate: rate,
        freight_charge: freight,
        fuel_levy_percent: @rate_card.fuel_levy_percent,
        fuel_levy_amount: fuel_levy,
        total_charge: freight + fuel_levy
      )
    end

    private

    # The tier with the highest starting weight that the shipment has reached.
    # Tiers 0 / 100 / 500 kg and a 720 kg shipment -> the 500 kg tier.
    # Done in Ruby over the (few) already-loaded rules, which also lets specs use unsaved cards.
    def rate_rule_for(chargeable_weight)
      @rate_card.rate_rules
        .select { |rule| rule.min_weight_kg <= chargeable_weight }
        .max_by(&:min_weight_kg) ||
        raise(PricingUnavailableError, "Rate card #{@rate_card.name} has no weight tier for #{chargeable_weight} kg")
    end

    def money(amount)
      amount.round(2, :half_up)
    end
  end
end
