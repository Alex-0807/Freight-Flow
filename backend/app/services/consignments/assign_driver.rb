module Consignments
  # Allocates a consignment to a driver, or reassigns it before pickup.
  #
  #   booked    -> allocated               (event: status_changed)
  #   allocated -> allocated, new driver   (event: driver_reassigned)
  #   allocated -> same driver again       no-op (a retry)
  #   anything else                        InvalidTransitionError (freight is already moving)
  class AssignDriver
    def self.call(...) = new(...).call

    def initialize(consignment:, driver:, actor:)
      @consignment = consignment
      @driver = driver
      @actor = actor
    end

    def call
      raise DriverUnavailableError.new(@driver) unless @driver.active?

      changed = @consignment.with_lock do
        if @consignment.booked?
          allocate!
        elsif @consignment.allocated?
          next false if @consignment.driver_id == @driver.id

          reassign!
        else
          raise InvalidTransitionError.new(from: @consignment.status, to: "allocated")
        end
        true
      end

      Result.new(consignment: @consignment, changed: changed)
    end

    private

    def allocate!
      @consignment.update!(driver: @driver, status: "allocated")
      @consignment.record_event!(
        event_type: "status_changed", actor: @actor,
        metadata: { driver_id: @driver.id, driver_name: @driver.name }
      )
    end

    def reassign!
      previous_driver = @consignment.driver
      @consignment.update!(driver: @driver)
      @consignment.record_event!(
        event_type: "driver_reassigned", actor: @actor,
        metadata: {
          from_driver_id: previous_driver.id, from_driver_name: previous_driver.name,
          driver_id: @driver.id, driver_name: @driver.name
        }
      )
    end
  end
end
