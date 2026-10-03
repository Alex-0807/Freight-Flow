module Api
  module V1
    # POST   /api/v1/session  { "email": "...", "password": "..." }  -> 201 { token, expires_at, user }
    # DELETE /api/v1/session                                         -> 204 (logs out this token)
    class SessionsController < BaseController
      skip_before_action :authenticate!, only: :create

      # Slows down password guessing: 10 attempts per IP per 3 minutes (Rails 8 built-in).
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
        render_error(:too_many_requests, "rate_limited", "Too many login attempts. Try again in a few minutes.")
      }

      def create
        email, password = params.require(%i[email password])
        # authenticate_by takes the same time whether or not the email exists,
        # so response timing can't reveal which emails have accounts.
        user = User.authenticate_by(email: email, password: password)
        return render_error(:unauthorized, "invalid_credentials", "Email or password is incorrect") unless user

        token = ApiToken.issue_for(user)
        render json: {
          token: token,
          expires_at: BaseSerializer.time(ApiToken::LIFETIME.from_now),
          user: UserSerializer.call(user)
        }, status: :created
      end

      def destroy
        current_api_token.destroy!
        head :no_content
      end
    end
  end
end
