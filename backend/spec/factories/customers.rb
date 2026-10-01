FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:code) { |n| "CUST#{n}" }
    billing_email { "billing@customer.test" }
  end
end
