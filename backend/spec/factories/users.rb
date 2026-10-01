FactoryBot.define do
  factory :user do
    name { "Dana Dispatcher" }
    sequence(:email) { |n| "user#{n}@freightflow.test" }
    password { "password123" }
    role { "dispatcher" }
  end
end
