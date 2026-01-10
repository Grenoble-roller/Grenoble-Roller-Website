FactoryBot.define do
  factory :attendance do
    association :user
    association :event
    status { 'registered' }
    stripe_customer_id { 'cus_test' }
    wants_reminder { false }
    free_trial_used { false }
    is_volunteer { false }
    needs_equipment { false }

    trait :paid do
      status { 'paid' }
    end

    trait :canceled do
      status { 'canceled' }
    end

    trait :with_reminder do
      wants_reminder { true }
    end

    trait :volunteer do
      is_volunteer { true }
    end

    trait :with_equipment do
      needs_equipment { true }
      roller_size { '38' }
    end
  end
end
