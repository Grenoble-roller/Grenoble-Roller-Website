# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_movement do
    association :inventory
    association :user, factory: :user
    quantity { 5 }
    reason { 'adjustment' }
    reference { nil }
    before_qty { 10 }
  end
end
