module Consignments
  # Books a consignment: builds it with its items, prices it, saves it and records the
  # "booked" tracking event, in one transaction.
  #
  #   Consignments::Create.call(customer: acme, attributes: { reference: "PO-1001", ... },
  #                             items: [{ description: "Pallet", quantity: 2, ... }], actor: dispatcher)
  #
  # The price is a snapshot: totals, rate card and every charge are copied onto the
  # consignment, so later rate card or fuel levy changes never reprice this booking.
  #
  # Raises ActiveRecord::RecordInvalid (bad input) or PricingUnavailableError (no rate card).
  class Create
    def self.call(...) = new(...).call

    def initialize(customer:, attributes:, items:, actor:)
      @customer = customer
      @attributes = attributes
      @items = items
      @actor = actor
    end

    def call
      consignment = Consignment.new(@attributes.merge(customer: @customer))
      @items.each { |item| consignment.consignment_items.build(item) }

      # Price only valid input. If an item is invalid (e.g. zero weight), we skip pricing,
      # and save! below reports the item errors instead of a confusing pricing error.
      apply_price(consignment) if priceable?(consignment)

      Consignment.transaction do
        consignment.save!
        consignment.record_event!(event_type: "status_changed", actor: @actor)
      end
      consignment
    end

    private

    def priceable?(consignment)
      @customer.present? && consignment.consignment_items.any? &&
        consignment.consignment_items.all?(&:valid?)
    end

    def apply_price(consignment)
      priced = Pricing::PriceShipment.call(customer: @customer, items: consignment.consignment_items)
      totals = priced.measurements
      quote = priced.quote

      consignment.assign_attributes(
        rate_card: priced.rate_card,
        total_items: totals.total_items,
        total_weight_kg: totals.weight_kg,
        total_volume_m3: totals.volume_m3,
        chargeable_weight_kg: quote.chargeable_weight_kg,
        freight_charge: quote.freight_charge,
        fuel_levy_percent: quote.fuel_levy_percent,
        fuel_levy_amount: quote.fuel_levy_amount,
        total_charge: quote.total_charge
      )
    end
  end
end
