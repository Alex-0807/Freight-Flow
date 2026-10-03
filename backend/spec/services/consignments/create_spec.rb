require "rails_helper"

RSpec.describe Consignments::Create do
  let!(:standard_card) { create(:rate_card, :with_standard_tiers, name: "Standard", is_default: true) }
  let(:customer) { create(:customer) }
  let(:dispatcher) { create(:user, role: "dispatcher") }

  let(:attributes) do
    {
      reference: "PO-1001", requested_delivery_date: Date.current + 2,
      pickup_address_line1: "1 Dock Road", pickup_suburb: "Port Melbourne", pickup_state: "VIC", pickup_postcode: "3207",
      delivery_address_line1: "9 Main Street", delivery_suburb: "Geelong", delivery_state: "VIC", delivery_postcode: "3220"
    }
  end
  let(:pallets) { { description: "Pallet", quantity: 2, weight_kg: "180", length_cm: 120, width_cm: 120, height_cm: 100 } }

  def book(items: [ pallets ], **overrides)
    described_class.call(customer: customer, attributes: attributes.merge(overrides), items: items, actor: dispatcher)
  end

  it "books, prices and snapshots the price on the consignment" do
    consignment = book

    expect(consignment).to be_persisted.and be_booked
    expect(consignment).to have_attributes(
      rate_card: standard_card, total_items: 2,
      total_weight_kg: BigDecimal("360"), total_volume_m3: BigDecimal("2.88"),
      chargeable_weight_kg: BigDecimal("720"), freight_charge: BigDecimal("277.00"),
      fuel_levy_percent: BigDecimal("18.50"), fuel_levy_amount: BigDecimal("51.25"),
      total_charge: BigDecimal("328.25")
    )
  end

  it "records the 'booked' tracking event with the dispatcher as actor" do
    consignment = book

    expect(consignment.tracking_events.sole).to have_attributes(
      event_type: "status_changed", status: "booked", user: dispatcher
    )
  end

  it "prices with the customer's own rate card when it has one" do
    contract = create(:rate_card, name: "Acme contract", base_charge: 0, minimum_charge: 0, fuel_levy_percent: 0)
    contract.rate_rules.create!(min_weight_kg: 0, per_kg_rate: "0.30")
    customer.update!(rate_card: contract)

    expect(book.total_charge).to eq(BigDecimal("216.00")) # 720 kg x 0.30, no base, no levy
  end

  it "keeps the booked price when the fuel levy changes later" do
    consignment = book

    standard_card.update!(fuel_levy_percent: "25.00")

    expect(consignment.reload.fuel_levy_amount).to eq(BigDecimal("51.25"))
    expect(consignment.total_charge).to eq(BigDecimal("328.25"))
  end

  it "reports invalid items as validation errors, naming the item, and saves nothing" do
    bad = pallets.merge(weight_kg: "0")

    expect { book(items: [ pallets, bad ]) }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors.attribute_names).to include(:"consignment_items[1].weight_kg")
      expect(error.record.errors.attribute_names).not_to include(:freight_charge)
    }
    expect(Consignment.count).to eq(0)
  end

  it "requires at least one item" do
    expect { book(items: []) }.to raise_error(ActiveRecord::RecordInvalid, /at least one item/)
  end

  it "rejects a duplicate reference for the same customer" do
    book

    expect { book }.to raise_error(ActiveRecord::RecordInvalid, /Reference has already been taken/)
  end

  it "raises PricingUnavailableError when no rate card applies, and saves nothing" do
    standard_card.update!(is_default: false)

    expect { book }.to raise_error(PricingUnavailableError)
    expect(Consignment.count).to eq(0)
  end
end
