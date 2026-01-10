# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partenaire #{n}" }
    sequence(:url) { |n| "https://partenaire#{n}.example.com" }
    sequence(:logo_url) { |n| "https://example.com/logo#{n}.png" }
    sequence(:description) { |n| "Description du partenaire #{n}" }
    is_active { true }

    trait :inactive do
      is_active { false }
    end
  end
end
