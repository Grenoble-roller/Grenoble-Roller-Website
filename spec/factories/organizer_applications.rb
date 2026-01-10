FactoryBot.define do
  factory :organizer_application do
    association :user
    status { 'pending' }
    motivation { 'Je souhaite devenir organisateur pour partager ma passion du roller.' }

    trait :approved do
      status { 'approved' }
      association :reviewed_by, factory: :user
      reviewed_at { Time.current }
    end

    trait :rejected do
      status { 'rejected' }
      association :reviewed_by, factory: :user
      reviewed_at { Time.current }
    end
  end
end
