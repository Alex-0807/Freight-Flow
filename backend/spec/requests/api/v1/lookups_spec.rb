require "rails_helper"

# The small endpoints behind the dispatcher's booking form.
RSpec.describe "Lookup and quote API" do
  let!(:standard_card) { create(:rate_card, :with_standard_tiers, name: "Standard", is_default: true) }
  let(:dispatcher) { create(:user, role: "dispatcher") }

  describe "GET /api/v1/me" do
    it "includes driver_id for a driver, so the app can load their jobs" do
      driver = create(:driver)

      get "/api/v1/me", headers: auth_headers(driver.user)

      expect(json["user"]).to include("role" => "driver", "driver_id" => driver.id)
    end
  end

  describe "GET /api/v1/customers" do
    it "lists customers with their rate card" do
      create(:customer, name: "Acme", rate_card: create(:rate_card, name: "Acme contract"))

      get "/api/v1/customers", headers: auth_headers(dispatcher)

      expect(json["customers"].sole).to include("name" => "Acme", "rate_card" => include("name" => "Acme contract"))
    end
  end

  describe "GET /api/v1/drivers" do
    it "lists active drivers with how many jobs each has on the go" do
      busy = create(:driver)
      create(:consignment, :allocated, driver: busy)
      create(:consignment, :in_transit, driver: busy)
      create(:consignment, :delivered, driver: busy) # finished: not counted
      idle = create(:driver)
      create(:driver, :inactive)

      get "/api/v1/drivers", headers: auth_headers(dispatcher)

      counts = json["drivers"].to_h { |d| [ d["id"], d["active_jobs_count"] ] }
      expect(counts).to eq(busy.id => 2, idle.id => 0)
    end

    it "is for dispatchers only" do
      get "/api/v1/drivers", headers: auth_headers(create(:driver).user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/quotes" do
    let(:customer) { create(:customer) }
    let(:pallets) { { description: "Pallet", quantity: 2, weight_kg: "180", length_cm: 120, width_cm: 120, height_cm: 100 } }

    it "prices a shipment without saving anything" do
      post "/api/v1/quotes", params: { quote: { customer_id: customer.id, items: [ pallets ] } },
        headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:ok)
      expect(json["quote"]).to include(
        "cubic_weight_kg" => "720.000", "per_kg_rate" => "0.3500",
        "freight_charge" => "277.00", "fuel_levy_amount" => "51.25", "total_charge" => "328.25"
      )
      expect(Consignment.count).to eq(0)
    end

    it "points at the invalid item" do
      post "/api/v1/quotes", params: { quote: { customer_id: customer.id, items: [ pallets.merge(quantity: 0) ] } },
        headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "details")).to have_key("items[0].quantity")
    end

    it "returns 404 for an unknown customer" do
      post "/api/v1/quotes", params: { quote: { customer_id: 0, items: [ pallets ] } },
        headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
