require "rails_helper"

RSpec.describe Consignment do
  describe "status safety net" do
    it "refuses to save a status change the lifecycle doesn't allow" do
      consignment = create(:consignment) # booked

      expect { consignment.update!(status: "delivered") }
        .to raise_error(ActiveRecord::RecordInvalid, /can't change from booked to delivered/)
      expect(consignment.reload).to be_booked
    end

    it "also blocks the enum shortcut delivered!, which would skip the services" do
      consignment = create(:consignment)

      expect { consignment.delivered! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows the next step in the lifecycle" do
      consignment = create(:consignment, :allocated)

      expect { consignment.update!(status: "picked_up") }.not_to raise_error
    end
  end
end
