module Api
  module V1
    # GET /api/v1/me -> the logged-in user. The app calls it at startup to check that a
    # saved token still works and to decide between driver and dispatcher screens.
    class MeController < BaseController
      def show
        render json: { user: UserSerializer.call(current_user) }
      end
    end
  end
end
