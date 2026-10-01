require "rails_helper"

RSpec.describe Consignment::StatusFlow do
  describe ".allowed?" do
    # The happy path, one step at a time.
    [
      %w[booked allocated],
      %w[allocated picked_up],
      %w[picked_up in_transit],
      %w[in_transit delivered]
    ].each do |from, to|
      it "allows #{from} -> #{to}" do
        expect(described_class.allowed?(from, to)).to be(true)
      end
    end

    # Skipping steps, going backwards, leaving the final state, unknown statuses.
    [
      %w[booked delivered],
      %w[booked picked_up],
      %w[allocated delivered],
      %w[in_transit picked_up],
      %w[delivered in_transit],
      %w[delivered booked],
      %w[booked lost]
    ].each do |from, to|
      it "rejects #{from} -> #{to}" do
        expect(described_class.allowed?(from, to)).to be(false)
      end
    end

    it "accepts symbols as well as strings" do
      expect(described_class.allowed?(:booked, :allocated)).to be(true)
    end
  end

  describe ".assert!" do
    it "raises InvalidTransitionError with a readable message" do
      expect { described_class.assert!("booked", "delivered") }
        .to raise_error(InvalidTransitionError, "Cannot change consignment status from booked to delivered")
    end

    it "returns quietly for an allowed move" do
      expect { described_class.assert!("booked", "allocated") }.not_to raise_error
    end
  end
end
