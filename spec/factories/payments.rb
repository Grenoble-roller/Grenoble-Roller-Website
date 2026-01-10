# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    provider { 'helloasso' }
    provider_payment_id { "PAY_#{SecureRandom.hex(8)}" }
    amount_cents { 5000 } # 50.00 EUR
    currency { 'EUR' }
    status { 'completed' }

    trait :pending do
      status { 'pending' }
    end

    trait :failed do
      status { 'failed' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :stripe do
      provider { 'stripe' }
      provider_payment_id { "pi_#{SecureRandom.hex(12)}" }
    end

    trait :helloasso do
      provider { 'helloasso' }
      provider_payment_id { "HA_#{SecureRandom.hex(8)}" }
    end
  end
end
