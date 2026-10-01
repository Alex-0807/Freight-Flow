require "rails_helper"

RSpec.describe Consignments::Deliver do
  let(:consignment) { create(:consignment, :in_transit) }
  let(:driver_user) { consignment.driver.user }

  def deliver(**overrides)
    described_class.call(consignment: consignment, actor: driver_user, receiver_name: "Sam Receiver", **overrides)
  end

  it "marks the consignment delivered and records POD and tracking event together" do
    delivered_at = 5.minutes.ago.change(usec: 0)

    result = deliver(delivered_at: delivered_at, notes: "Left at dock 3")

    expect(result).to be_changed
    expect(consignment.reload).to be_delivered
    expect(consignment.proof_of_delivery).to have_attributes(
      receiver_name: "Sam Receiver", delivered_at: delivered_at, notes: "Left at dock 3"
    )
    expect(consignment.tracking_events.last).to have_attributes(status: "delivered", occurred_at: delivered_at)
  end

  it "rolls everything back when the proof of delivery is invalid" do
    expect { deliver(receiver_name: "") }.to raise_error(ActiveRecord::RecordInvalid, /Receiver name/)

    expect(consignment.reload).to be_in_transit
    expect(consignment.proof_of_delivery).to be_nil
    expect(consignment.tracking_events).to be_empty
  end

  it "is idempotent: a retried delivery keeps the first POD and writes nothing" do
    deliver(receiver_name: "Sam Receiver")

    result = deliver(receiver_name: "Someone Else")

    expect(result).not_to be_changed
    expect(consignment.reload.proof_of_delivery.receiver_name).to eq("Sam Receiver")
    expect(consignment.tracking_events.where(status: "delivered").count).to eq(1)
  end

  it "refuses to deliver freight that hasn't been picked up" do
    allocated = create(:consignment, :allocated)

    expect {
      described_class.call(consignment: allocated, actor: driver_user, receiver_name: "Sam")
    }.to raise_error(InvalidTransitionError)
    expect(allocated.reload.proof_of_delivery).to be_nil
  end
end
