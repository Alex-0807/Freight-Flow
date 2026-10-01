FactoryBot.define do
  factory :driver do
    user { association :user, name: "Mia Driver", role: "driver" }
    phone { "0400 000 000" }
    sequence(:vehicle_registration) { |n| "FF#{n.to_s.rjust(4, '0')}" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
