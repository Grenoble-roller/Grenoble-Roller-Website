# frozen_string_literal: true

FactoryBot.define do
  factory :inventory do
    association :product_variant
    stock_qty { 10 }
    reserved_qty { 0 }
  end
end
