module ApiHelpers
  # Headers for an authenticated JSON request as the given user.
  def auth_headers(user)
    { "Authorization" => "Bearer #{ApiToken.issue_for(user)}", "Accept" => "application/json" }
  end

  # The parsed JSON body, with string keys, as the Flutter app would see it.
  def json
    response.parsed_body
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
