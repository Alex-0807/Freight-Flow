require "rails_helper"

RSpec.describe "Consignments API" do
  let!(:standard_card) { create(:rate_card, :with_standard_tiers, name: "Standard", is_default: true) }
  let(:dispatcher) { create(:user, role: "dispatcher") }
  let(:customer) { create(:customer, name: "Acme Logistics", code: "ACME") }

  describe "POST /api/v1/consignments" do
    let(:payload) do
      {
        consignment: {
          customer_id: customer.id,
          reference: "PO-1001",
          requested_delivery_date: (Date.current + 2).iso8601,
          pickup: { address_line1: "1 Dock Road", suburb: "Port Melbourne", state: "VIC", postcode: "3207" },
          delivery: { address_line1: "9 Main Street", suburb: "Geelong", state: "VIC", postcode: "3220",
                      instructions: "Dock 3, ask for Sam" },
          items: [ { description: "Pallet", quantity: 2, weight_kg: "180", length_cm: 120, width_cm: 120, height_cm: 100 } ]
        }
      }
    end

    it "books and prices the consignment (201)" do
      post "/api/v1/consignments", params: payload, headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:created)
      body = json["consignment"]
      expect(body).to include("reference" => "PO-1001", "status" => "booked", "total_charge" => "328.25")
      expect(body["pricing"]).to include(
        "chargeable_weight_kg" => "720.000", "freight_charge" => "277.00",
        "fuel_levy_amount" => "51.25", "total_charge" => "328.25"
      )
      expect(body["delivery"]).to include("suburb" => "Geelong", "instructions" => "Dock 3, ask for Sam")
      expect(body["items"].sole).to include("quantity" => 2, "weight_kg" => "180.000")
    end

    it "returns 422 with field errors for invalid input" do
      payload[:consignment][:pickup][:postcode] = "ABC"
      payload[:consignment][:items][0][:weight_kg] = "0"

      post "/api/v1/consignments", params: payload, headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "code")).to eq("validation_failed")
      expect(json.dig("error", "details").keys).to include("pickup_postcode", "consignment_items[0].weight_kg")
    end

    it "returns 422 for a duplicate reference" do
      2.times { post "/api/v1/consignments", params: payload, headers: auth_headers(dispatcher), as: :json }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "details", "reference")).to eq([ "has already been taken" ])
    end

    it "returns 422 pricing_unavailable when no rate card applies" do
      standard_card.update!(is_default: false)

      post "/api/v1/consignments", params: payload, headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "code")).to eq("pricing_unavailable")
    end

    it "returns 400 when the body isn't shaped like a consignment" do
      post "/api/v1/consignments", params: { consignment: "PO-1" }, headers: auth_headers(dispatcher), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "code")).to eq("bad_request")
    end

    it "forbids drivers from booking (403)" do
      driver = create(:driver)

      post "/api/v1/consignments", params: payload, headers: auth_headers(driver.user), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(Consignment.count).to eq(0)
    end
  end

  describe "GET /api/v1/consignments" do
    it "lists newest first, filters by status, and paginates" do
      old = create(:consignment, customer: customer, created_at: 2.days.ago)
      create(:consignment, :allocated, customer: customer, created_at: 1.day.ago)
      newest = create(:consignment, customer: customer)

      get "/api/v1/consignments", params: { status: "booked", per_page: 1 }, headers: auth_headers(dispatcher)

      expect(response).to have_http_status(:ok)
      expect(json["consignments"].map { |c| c["id"] }).to eq([ newest.id ])
      expect(json["meta"]).to eq("page" => 1, "per_page" => 1, "total_count" => 2)

      get "/api/v1/consignments", params: { status: "booked", per_page: 1, page: 2 }, headers: auth_headers(dispatcher)
      expect(json["consignments"].map { |c| c["id"] }).to eq([ old.id ])
    end

    it "uses a fixed number of queries however many consignments there are (no N+1)" do
      create_list(:consignment, 2, :allocated)
      headers = auth_headers(dispatcher)
      count_queries = lambda do
        count = 0
        callback = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:sql].start_with?("UPDATE") }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get "/api/v1/consignments", headers: headers }
        count
      end

      queries_for_two = count_queries.call
      create_list(:consignment, 5, :allocated)

      expect(count_queries.call).to eq(queries_for_two)
    end
  end

  describe "GET /api/v1/consignments/:id" do
    let(:consignment) { create(:consignment, :allocated, customer: customer) }

    it "shows the detail to a dispatcher" do
      get "/api/v1/consignments/#{consignment.id}", headers: auth_headers(dispatcher)

      expect(response).to have_http_status(:ok)
      expect(json.dig("consignment", "customer", "code")).to eq("ACME")
      expect(json.dig("consignment", "driver", "name")).to eq("Mia Driver")
    end

    it "shows the detail to the assigned driver" do
      get "/api/v1/consignments/#{consignment.id}", headers: auth_headers(consignment.driver.user)

      expect(response).to have_http_status(:ok)
    end

    it "forbids another driver (403)" do
      get "/api/v1/consignments/#{consignment.id}", headers: auth_headers(create(:driver).user)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/consignments/999999", headers: auth_headers(dispatcher)

      expect(response).to have_http_status(:not_found)
      expect(json.dig("error", "code")).to eq("not_found")
    end
  end
end
