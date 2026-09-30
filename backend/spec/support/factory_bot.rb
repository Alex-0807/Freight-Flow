# Lets specs call create(:consignment) instead of FactoryBot.create(:consignment).
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
