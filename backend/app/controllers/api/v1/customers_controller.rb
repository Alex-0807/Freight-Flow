module Api
  module V1
    # GET /api/v1/customers -> customer picker for the dispatcher's booking form.
    class CustomersController < BaseController
      before_action :require_dispatcher!

      def index
        # includes(:rate_card): one extra query for all rate cards, instead of one per customer.
        customers = Customer.includes(:rate_card).order(:name)
        render json: { customers: customers.map { |customer| CustomerSerializer.call(customer) } }
      end
    end
  end
end
