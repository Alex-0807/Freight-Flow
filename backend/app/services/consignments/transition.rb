module Consignments
  # Moves a consignment one step along its lifecycle and records a tracking event.
  #
  #   Consignments::Transition.call(consignment: c, to: "picked_up", actor: current_user)
  #
  # Guarantees:
  # - Atomic: the status change and its tracking event are saved together or not at all.
  # - Serialised: the row is locked (SELECT ... FOR UPDATE), so two requests for the same
  #   consignment run one after the other, never interleaved.
  # - Idempotent: if the consignment is already in the target status (a retried request),
  #   nothing is written and the result says changed? == false.
  #
  # An optional block runs inside the same transaction, after the status change.
  # Deliver uses it to create the proof of delivery atomically with the status.
  class Transition
    # Keyword arguments go to the constructor, the block goes to #call.
    # (A bare `new(...).call` would hand the block to `new`, which silently ignores it.)
    def self.call(**, &) = new(**).call(&)

    def initialize(consignment:, to:, actor:, occurred_at: nil, latitude: nil, longitude: nil)
      @consignment = consignment
      @to = to.to_s
      @actor = actor
      @occurred_at = occurred_at || Time.current
      @latitude = latitude
      @longitude = longitude
    end

    def call(&inside_transaction)
      # with_lock = BEGIN; SELECT ... FOR UPDATE; (reload the row); run the block; COMMIT.
      # If anything in the block raises, everything rolls back.
      changed = @consignment.with_lock do
        next false if @consignment.status == @to # already done: a retry of a request that succeeded

        Consignment::StatusFlow.assert!(@consignment.status, @to)
        @consignment.update!(status: @to)
        @consignment.record_event!(
          event_type: "status_changed", actor: @actor, occurred_at: @occurred_at,
          latitude: @latitude, longitude: @longitude
        )
        inside_transaction&.call(@consignment)
        true
      end

      Result.new(consignment: @consignment, changed: changed)
    end
  end
end
