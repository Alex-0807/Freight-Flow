module Api
  module V1
    # GET /api/v1/drivers -> active drivers with how many jobs each has on the go,
    # so the dispatcher can pick a driver who isn't overloaded.
    class DriversController < BaseController
      before_action :require_dispatcher!

      ACTIVE_JOB_STATUSES = %w[allocated picked_up in_transit].freeze

      def index
        # Counting jobs per driver with a subquery keeps this to two queries in total
        # (drivers + their users), however many drivers there are. Calling
        # driver.consignments.count inside the loop would run one extra query per driver (N+1).
        active_jobs = Consignment.where("consignments.driver_id = drivers.id")
          .where(status: ACTIVE_JOB_STATUSES).select("COUNT(*)")
        drivers = Driver.active.includes(:user)
          .select("drivers.*", "(#{active_jobs.to_sql}) AS active_jobs_count")
          .order(:id)

        render json: { drivers: drivers.map { |driver| DriverSerializer.call(driver) } }
      end
    end
  end
end
