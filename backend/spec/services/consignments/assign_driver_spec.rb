require "rails_helper"

RSpec.describe Consignments::AssignDriver do
  let(:dispatcher) { create(:user, role: "dispatcher") }
  let(:driver) { create(:driver) }

  context "when the consignment is booked" do
    let(:consignment) { create(:consignment) }

    it "allocates it to the driver and records who and when" do
      result = described_class.call(consignment: consignment, driver: driver, actor: dispatcher)

      expect(result).to be_changed
      expect(consignment.reload).to be_allocated
      expect(consignment.driver).to eq(driver)

      event = consignment.tracking_events.last
      expect(event).to have_attributes(event_type: "status_changed", status: "allocated", user: dispatcher)
      expect(event.metadata).to include("driver_id" => driver.id, "driver_name" => "Mia Driver")
    end
  end

  context "when the consignment is already allocated" do
    let(:consignment) { create(:consignment, :allocated) }

    it "reassigns to a different driver without changing status" do
      previous_driver = consignment.driver

      result = described_class.call(consignment: consignment, driver: driver, actor: dispatcher)

      expect(result).to be_changed
      expect(consignment.reload.driver).to eq(driver)
      expect(consignment).to be_allocated
      event = consignment.tracking_events.last
      expect(event).to have_attributes(event_type: "driver_reassigned", status: "allocated")
      expect(event.metadata).to include("from_driver_id" => previous_driver.id, "driver_id" => driver.id)
    end

    it "treats assigning the same driver again as a no-op retry" do
      result = described_class.call(consignment: consignment, driver: consignment.driver, actor: dispatcher)

      expect(result).not_to be_changed
      expect(consignment.tracking_events.count).to eq(0)
    end
  end

  it "refuses once the freight has been picked up" do
    consignment = create(:consignment, :picked_up)

    expect { described_class.call(consignment: consignment, driver: driver, actor: dispatcher) }
      .to raise_error(InvalidTransitionError)
    expect(consignment.reload.driver).not_to eq(driver)
  end

  it "refuses an inactive driver" do
    consignment = create(:consignment)
    inactive = create(:driver, :inactive)

    expect { described_class.call(consignment: consignment, driver: inactive, actor: dispatcher) }
      .to raise_error(DriverUnavailableError)
    expect(consignment.reload).to be_booked
  end
end
