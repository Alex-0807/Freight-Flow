require "rails_helper"

RSpec.describe Consignments::Transition do
  let(:consignment) { create(:consignment, :allocated) }
  let(:driver_user) { consignment.driver.user }

  it "moves to the next status and records a tracking event with location" do
    picked_up_at = 10.minutes.ago.change(usec: 0)

    result = described_class.call(
      consignment: consignment, to: "picked_up", actor: driver_user,
      occurred_at: picked_up_at, latitude: -37.8395, longitude: 144.9380
    )

    expect(result).to be_changed
    expect(consignment.reload).to be_picked_up
    expect(consignment.tracking_events.last).to have_attributes(
      event_type: "status_changed", status: "picked_up", user: driver_user,
      occurred_at: picked_up_at, latitude: BigDecimal("-37.8395"), longitude: BigDecimal("144.938")
    )
  end

  it "treats a repeated request as a no-op instead of an error (mobile retries)" do
    described_class.call(consignment: consignment, to: "picked_up", actor: driver_user)

    result = described_class.call(consignment: consignment, to: "picked_up", actor: driver_user)

    expect(result).not_to be_changed
    expect(consignment.tracking_events.where(status: "picked_up").count).to eq(1)
  end

  it "rejects skipping steps and writes nothing" do
    expect { described_class.call(consignment: consignment, to: "delivered", actor: driver_user) }
      .to raise_error(InvalidTransitionError, /from allocated to delivered/)

    expect(consignment.reload).to be_allocated
    expect(consignment.tracking_events).to be_empty
  end

  it "rolls back the status change if the tracking event is invalid" do
    expect {
      described_class.call(consignment: consignment, to: "picked_up", actor: driver_user, latitude: -37.8)
    }.to raise_error(ActiveRecord::RecordInvalid, /latitude and longitude/)

    expect(consignment.reload).to be_allocated
  end
end
