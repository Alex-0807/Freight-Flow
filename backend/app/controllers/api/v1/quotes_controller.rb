module Api
  module V1
    # POST /api/v1/quotes -> price preview for the booking form. Saves nothing.
    #
    #   { "quote": { "customer_id": 1,
    #                "items": [{ "description": "Pallet", "quantity": 2, "weight_kg": "180",
    #                            "length_cm": 120, "width_cm": 120, "height_cm": 100 }] } }
    class QuotesController < BaseController
      before_action :require_dispatcher!

      ITEM_FIELDS = %i[description quantity weight_kg length_cm width_cm height_cm].freeze

      def create
        quote_params = params.expect(quote: [ :customer_id, items: [ ITEM_FIELDS ] ])
        customer = Customer.find(quote_params[:customer_id])

        # Build the items on an unsaved consignment, so they use the same validations
        # and the same weight/volume helpers as a real booking.
        draft = Consignment.new
        items = Array(quote_params[:items]).map { |item| draft.consignment_items.build(item.to_h) }
        return render_item_errors(items) if items.empty? || items.any?(&:invalid?)

        priced = Pricing::PriceShipment.call(customer: customer, items: items)
        render json: { quote: QuoteSerializer.call(priced) }
      end

      private

      def render_item_errors(items)
        details = if items.empty?
          { items: [ "must include at least one item" ] }
        else
          items.each_with_index.each_with_object({}) do |(item, index), errors|
            item.errors.each { |error| (errors["items[#{index}].#{error.attribute}"] ||= []) << error.message }
          end
        end
        render_error(:unprocessable_content, "validation_failed", "Items are invalid", details)
      end
    end
  end
end
