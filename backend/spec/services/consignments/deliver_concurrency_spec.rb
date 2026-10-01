require "rails_helper"

# Two requests delivering the same consignment at the same moment, e.g. the driver's
# app retries while the first request is still running.
#
# Normal specs run inside a transaction that is rolled back at the end, but threads use
# their own database connections and couldn't see that uncommitted data. So this spec
# really commits, and cleans up after itself.
RSpec.describe "Delivering the same consignment concurrently" do
  self.use_transactional_tests = false

  after do
    # Children before parents, so foreign keys never block a delete.
    [ TrackingEvent, ProofOfDelivery, ConsignmentItem, Consignment, Driver, Customer, RateCard, User ]
      .each(&:delete_all)
  end

  it "delivers exactly once: one POD, one delivered event, one 'changed' result" do
    consignment = create(:consignment, :in_transit)
    actor = consignment.driver.user
    start = Concurrent::CountDownLatch.new(1)

    threads = Array.new(2) do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          start.wait # hold both threads until they can start together
          Consignments::Deliver.call(
            consignment: Consignment.find(consignment.id), actor: actor, receiver_name: "Receiver #{i}"
          )
        end
      end
    end
    start.count_down
    results = threads.map(&:value)

    expect(results.count(&:changed?)).to eq(1)
    expect(ProofOfDelivery.where(consignment_id: consignment.id).count).to eq(1)
    expect(TrackingEvent.where(consignment_id: consignment.id, status: "delivered").count).to eq(1)
  end
end
