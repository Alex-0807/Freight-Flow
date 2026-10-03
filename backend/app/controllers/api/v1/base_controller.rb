module Api
  module V1
    # Every /api/v1 controller inherits from this. It provides:
    #   1. Authentication: a valid "Authorization: Bearer <token>" header, or 401.
    #   2. Authorization helpers: require_dispatcher!, authorize_consignment!.
    #   3. One error format for every failure, mapped from exceptions in one place:
    #        { "error": { "code": "...", "message": "...", "details": { ... } } }
    #
    # Controllers and services just raise; they never build error JSON themselves.
    class BaseController < ApplicationController
      include ActionController::HttpAuthentication::Token::ControllerMethods

      # Order matters: Rails checks rescue_from handlers bottom-up, so the most general
      # handler (DomainError) comes before its more specific subclasses.
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_validation_failed
      rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ForbiddenError, with: :render_forbidden
      rescue_from DomainError, with: :render_domain_error
      rescue_from PricingUnavailableError, with: :render_pricing_unavailable
      rescue_from DriverUnavailableError, with: :render_driver_unavailable
      rescue_from InvalidTransitionError, with: :render_invalid_transition

      before_action :authenticate!

      private

      attr_reader :current_user, :current_api_token

      def authenticate!
        @current_api_token = authenticate_with_http_token { |token, _options| ApiToken.find_active(token) }

        if @current_api_token
          @current_user = @current_api_token.user
          @current_api_token.touch_last_used!
        else
          response.headers["WWW-Authenticate"] = 'Bearer realm="FreightFlow"'
          render_error(:unauthorized, "unauthorized", "Missing, invalid or expired token")
        end
      end

      def require_dispatcher!
        raise ForbiddenError, "Only dispatchers can do that" unless current_user.dispatcher?
      end

      # Dispatchers see every consignment; a driver sees only the jobs assigned to them.
      def authorize_consignment!(consignment)
        return if current_user.dispatcher?
        return if consignment.driver.present? && consignment.driver.user_id == current_user.id

        raise ForbiddenError, "This consignment is not assigned to you"
      end

      # page / per_page query params -> [records for this page, meta hash for the response]
      def paginate(scope)
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = params.fetch(:per_page, 25).to_i.clamp(1, 100)
        records = scope.limit(per_page).offset((page - 1) * per_page)

        [ records, { page: page, per_page: per_page, total_count: scope.count } ]
      end

      def render_error(status, code, message, details = nil)
        body = { code: code, message: message }
        body[:details] = details if details.present?
        render json: { error: body }, status: status
      end

      def render_not_found(error)
        render_error(:not_found, "not_found", "#{error.model || 'Record'} not found")
      end

      def render_validation_failed(error)
        render_error(:unprocessable_content, "validation_failed",
          "#{error.record.class.model_name.human} could not be saved", error.record.errors.to_hash)
      end

      # A unique index fired after validations passed: two identical requests raced.
      def render_conflict(_error)
        render_error(:conflict, "conflict", "This record was just created by another request")
      end

      def render_bad_request(error)
        render_error(:bad_request, "bad_request", error.message)
      end

      def render_forbidden(error)
        render_error(:forbidden, "forbidden", error.message)
      end

      def render_domain_error(error)
        render_error(:unprocessable_content, "domain_error", error.message)
      end

      def render_pricing_unavailable(error)
        render_error(:unprocessable_content, "pricing_unavailable", error.message)
      end

      def render_driver_unavailable(error)
        render_error(:unprocessable_content, "driver_unavailable", error.message)
      end

      # The request was well-formed but conflicts with the consignment's current status.
      def render_invalid_transition(error)
        render_error(:conflict, "invalid_transition", error.message, { from: error.from, to: error.to })
      end
    end
  end
end
