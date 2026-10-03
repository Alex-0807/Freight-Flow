require "rails_helper"

RSpec.describe Pricing::RateCardResolver do
  let!(:default_card) { create(:rate_card, name: "Standard", is_default: true) }

  it "uses the customer's own rate card when it has one" do
    special = create(:rate_card, name: "Acme contract")
    customer = create(:customer, rate_card: special)

    expect(described_class.call(customer)).to eq(special)
  end

  it "falls back to the default rate card" do
    expect(described_class.call(create(:customer))).to eq(default_card)
  end

  it "raises when there is no customer card and no default" do
    default_card.update!(is_default: false)
    customer = create(:customer, code: "NOCARD")

    expect { described_class.call(customer) }
      .to raise_error(PricingUnavailableError, /No rate card for customer NOCARD/)
  end
end
