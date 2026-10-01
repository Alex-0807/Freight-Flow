module Consignments
  # Completes a delivery: in_transit -> delivered, plus proof of delivery and a tracking
  # event, all in one transaction. If the POD is invalid (e.g. no receiver name), the
  # status change and event roll back too, so a consignment can never be "delivered"
  # without a POD.
  #
  # Calling it again for an already-delivered consignment is a no-op (changed? == false),
  # and the existing POD is kept.
  class Deliver
    def self.call(...) = new(...).call

    def initialize(consignment:, actor:, receiver_name:, delivered_at: nil, notes: nil,
                   latitude: nil, longitude: nil)
      @consignment = consignment
      @actor = actor
      @receiver_name = receiver_name
      @delivered_at = delivered_at || Time.current
      @notes = notes
      @latitude = latitude
      @longitude = longitude
    end

    def call
      result = Transition.call(
        consignment: @consignment, to: "delivered", actor: @actor,
        occurred_at: @delivered_at, latitude: @latitude, longitude: @longitude
      ) do |consignment|
        consignment.create_proof_of_delivery!(
          receiver_name: @receiver_name, delivered_at: @delivered_at, notes: @notes
        )
      end

      # Step 8 adds here, only when the result changed? and only after the transaction
      # has committed: GenerateInvoiceJob and SendDeliveryNotificationJob.
      result
    end
  end
end
