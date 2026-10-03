require "rails_helper"

RSpec.describe Pricing::FreightCalculator do
  # Unsaved card + tiers: the calculator is pure, so these specs never touch the database.
  let(:card) { build(:rate_card, :with_standard_tiers) }

  def price(weight_kg:, volume_m3:, rate_card: card)
    described_class.call(rate_card: rate_card, weight_kg: weight_kg, volume_m3: volume_m3)
  end

  describe "the worked examples from docs/architecture.md" do
    it "prices bulky freight on cubic weight: 2 pallets 120x120x100 cm, 180 kg each" do
      quote = price(weight_kg: 360, volume_m3: "2.880")

      expect(quote).to have_attributes(
        dead_weight_kg: BigDecimal("360"),
        cubic_weight_kg: BigDecimal("720"),   # 2.88 m3 x 250 kg/m3 beats 360 kg dead weight
        chargeable_weight_kg: BigDecimal("720"),
        per_kg_rate: BigDecimal("0.35"),      # 500 kg+ tier
        freight_charge: BigDecimal("277.00"), # 25.00 + 720 x 0.35
        fuel_levy_amount: BigDecimal("51.25"), # 277 x 18.5% = 51.245, rounded half-up
        total_charge: BigDecimal("328.25")
      )
    end

    it "applies the minimum charge to a small carton: 30x30x30 cm, 3 kg" do
      quote = price(weight_kg: 3, volume_m3: "0.027")

      expect(quote).to have_attributes(
        cubic_weight_kg: BigDecimal("6.75"),
        chargeable_weight_kg: BigDecimal("7"), # rounded up to a whole kg
        freight_charge: BigDecimal("45.00"),  # 25 + 7 x 0.55 = 28.85, below the 45.00 minimum
        fuel_levy_amount: BigDecimal("8.33"), # 45 x 18.5% = 8.325, rounded half-up
        total_charge: BigDecimal("53.33")
      )
    end
  end

  describe "chargeable weight" do
    it "uses dead weight for dense freight" do
      quote = price(weight_kg: 300, volume_m3: "0.125") # cubic weight only 31.25 kg

      expect(quote.chargeable_weight_kg).to eq(300)
      expect(quote.freight_charge).to eq(BigDecimal("151.00")) # 25 + 300 x 0.42
    end

    it "rounds a fractional weight up, never down" do
      expect(price(weight_kg: "100.001", volume_m3: 0).chargeable_weight_kg).to eq(101)
    end
  end

  describe "weight tiers" do
    it "uses a tier from exactly its starting weight" do
      expect(price(weight_kg: 100, volume_m3: 0).per_kg_rate).to eq(BigDecimal("0.42"))
    end

    it "uses the lower tier just below the threshold" do
      expect(price(weight_kg: 99, volume_m3: 0).per_kg_rate).to eq(BigDecimal("0.55"))
    end

    it "fails clearly when no tier covers the weight" do
      card = build(:rate_card, name: "Pallets only")
      card.rate_rules.build(min_weight_kg: 50, per_kg_rate: "0.40")

      expect { price(weight_kg: 10, volume_m3: 0, rate_card: card) }
        .to raise_error(PricingUnavailableError, /Pallets only has no weight tier for 10 kg/)
    end

    it "fails clearly when the card has no tiers at all" do
      expect { price(weight_kg: 10, volume_m3: 0, rate_card: build(:rate_card)) }
        .to raise_error(PricingUnavailableError)
    end
  end

  describe "decimal precision" do
    it "returns BigDecimal money, never Float" do
      quote = price(weight_kg: 360, volume_m3: "2.880")

      expect([ quote.freight_charge, quote.fuel_levy_amount, quote.total_charge ]).to all(be_a(BigDecimal))
    end

    it "keeps 4-decimal rates exact until the final rounding" do
      card = build(:rate_card, base_charge: 0, minimum_charge: 0, fuel_levy_percent: 0)
      card.rate_rules.build(min_weight_kg: 0, per_kg_rate: "0.4575")

      # 7 x 0.4575 = 3.2025 exactly; rounding to cents happens once, at the end -> 3.20.
      expect(price(weight_kg: 7, volume_m3: 0, rate_card: card).freight_charge).to eq(BigDecimal("3.20"))
    end

    it "doesn't overcharge a kilo because of float drift" do
      # Items of 0.1 + 2.7 + 0.2 kg. As floats that sum is 3.0000000000000004,
      # which rounds UP to 4 kg. As BigDecimal it is exactly 3 kg.
      items = [ "0.1", "2.7", "0.2" ].map { |kg| build(:consignment_item, quantity: 1, weight_kg: kg) }
      weight = Pricing::Measurements.from_items(items).weight_kg

      expect(0.1 + 2.7 + 0.2).to be > 3 # the float problem this guards against
      expect(price(weight_kg: weight, volume_m3: 0).chargeable_weight_kg).to eq(3)
    end

    it "keeps the total exactly equal to freight + levy (the database checks this too)" do
      quote = price(weight_kg: 3, volume_m3: "0.027")

      expect(quote.total_charge).to eq(quote.freight_charge + quote.fuel_levy_amount)
    end
  end

  describe "fuel levy" do
    it "follows the card's current percentage" do
      card.fuel_levy_percent = BigDecimal("20.00")

      quote = price(weight_kg: 360, volume_m3: "2.880")

      expect(quote.freight_charge).to eq(BigDecimal("277.00")) # freight unchanged
      expect(quote.fuel_levy_amount).to eq(BigDecimal("55.40"))
      expect(quote.fuel_levy_percent).to eq(BigDecimal("20.00"))
    end

    it "is zero when the card has no levy" do
      card.fuel_levy_percent = 0

      expect(price(weight_kg: 360, volume_m3: "2.880").total_charge).to eq(BigDecimal("277.00"))
    end
  end

  describe "invalid input" do
    it "rejects zero weight" do
      expect { price(weight_kg: 0, volume_m3: 1) }.to raise_error(ArgumentError, /weight must be greater than zero/)
    end

    it "rejects negative weight" do
      expect { price(weight_kg: -5, volume_m3: 1) }.to raise_error(ArgumentError)
    end

    it "rejects negative volume" do
      expect { price(weight_kg: 5, volume_m3: "-0.1") }.to raise_error(ArgumentError, /volume/)
    end
  end
end
