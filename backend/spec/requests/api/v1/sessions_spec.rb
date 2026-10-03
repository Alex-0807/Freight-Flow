require "rails_helper"

RSpec.describe "Sessions API" do
  let!(:user) { create(:user, email: "dana@freightflow.test", password: "password123") }

  describe "POST /api/v1/session" do
    it "logs in and returns a token that works on the next request" do
      post "/api/v1/session", params: { email: "Dana@FreightFlow.test", password: "password123" }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["user"]).to include("email" => "dana@freightflow.test", "role" => "dispatcher")

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{json['token']}" }
      expect(response).to have_http_status(:ok)
      expect(json.dig("user", "id")).to eq(user.id)
    end

    it "stores only a digest of the token, never the token itself" do
      post "/api/v1/session", params: { email: user.email, password: "password123" }, as: :json

      stored = ApiToken.sole
      expect(stored.token_digest).not_to eq(json["token"])
      expect(stored.token_digest).to eq(ApiToken.digest(json["token"]))
    end

    it "rejects a wrong password with 401 and the standard error format" do
      post "/api/v1/session", params: { email: user.email, password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to include("code" => "invalid_credentials")
      expect(ApiToken.count).to eq(0)
    end

    it "returns 400 when the password is missing" do
      post "/api/v1/session", params: { email: user.email }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "code")).to eq("bad_request")
    end
  end

  describe "DELETE /api/v1/session" do
    it "revokes the token, so it stops working" do
      headers = auth_headers(user)

      delete "/api/v1/session", headers: headers
      expect(response).to have_http_status(:no_content)

      get "/api/v1/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "authentication on protected endpoints" do
    it "rejects requests without a token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json.dig("error", "code")).to eq("unauthorized")
    end

    it "rejects an expired token" do
      headers = auth_headers(user)
      ApiToken.update_all(expires_at: 1.minute.ago)

      get "/api/v1/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
