FactoryBot.define do
  factory :audit_log do
    sequence(:target_id) { |n| n }
    action { "created" }
    target_type { "Event" }
    metadata { {} }

    trait :with_actor do
      association :actor_user, factory: :user
    end
  end
end
