module Api
  module V1
    # GET  /api/v1/consignments        dispatcher board: filter by status, customer_id, driver_id; paginated
    # GET  /api/v1/consignments/:id    detail: dispatcher, or the driver it's assigned to
    # POST /api/v1/consignments        book and price a consignment (dispatcher)
    class ConsignmentsController < BaseController
      before_action :require_dispatcher!, only: %i[index create]

      ITEM_FIELDS = %i[description quantity weight_kg length_cm width_cm height_cm].freeze
      ADDRESS_FIELDS = %i[address_line1 suburb state postcode].freeze

      def index
        scope = Consignment.includes(:customer, driver: :user).order(created_at: :desc, id: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?

        consignments, meta = paginate(scope)
        render json: { consignments: consignments.map { |c| ConsignmentSerializer.summary(c) }, meta: meta }
      end

      def show
        consignment = Consignment
          .includes(:customer, :rate_card, :consignment_items, :proof_of_delivery, :invoice, driver: :user)
          .find(params[:id])
        authorize_consignment!(consignment)

        render json: { consignment: ConsignmentSerializer.detail(consignment) }
      end

      def create
        input = params.expect(consignment: [
          :customer_id, :reference, :requested_delivery_date,
          pickup: ADDRESS_FIELDS, delivery: [ *ADDRESS_FIELDS, :instructions ], items: [ ITEM_FIELDS ]
        ])

        consignment = Consignments::Create.call(
          customer: Customer.find_by(id: input[:customer_id]), # nil -> "Customer must exist" (422)
          attributes: consignment_attributes(input),
          items: Array(input[:items]).map(&:to_h),
          actor: current_user
        )

        render json: { consignment: ConsignmentSerializer.detail(consignment) }, status: :created
      end

      private

      # The API nests addresses ({ pickup: { suburb: ... } }); the table has flat columns.
      def consignment_attributes(input)
        pickup = input[:pickup] || {}
        delivery = input[:delivery] || {}

        {
          reference: input[:reference],
          requested_delivery_date: input[:requested_delivery_date],
          pickup_address_line1: pickup[:address_line1],
          pickup_suburb: pickup[:suburb],
          pickup_state: pickup[:state],
          pickup_postcode: pickup[:postcode],
          delivery_address_line1: delivery[:address_line1],
          delivery_suburb: delivery[:suburb],
          delivery_state: delivery[:state],
          delivery_postcode: delivery[:postcode],
          delivery_instructions: delivery[:instructions]
        }
      end
    end
  end
end
