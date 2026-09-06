# frozen_string_literal: true

class Checkout < ApplicationRecord
  include Auditable

  belongs_to :user
  belongs_to :payment, optional: true
  has_many :checkout_lines, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    paid: "paid",
    failed: "failed",
    abandoned: "abandoned"
  }, validate: true

  validates :subtotal_cents, :donation_cents, :total_cents,
            numericality: { greater_than_or_equal_to: 0 }
  validate :total_equals_subtotal_plus_donation

  def self.ransackable_attributes(_auth_object = nil)
    %w[status subtotal_cents donation_cents total_cents created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user payment]
  end

  def product_order
    order_id = metadata["order_id"]
    return nil unless order_id

    user.orders.find_by(id: order_id)
  end

  private

  def audit_actor
    user
  end

  def audit_attributes
    {
      user_id: user_id,
      payment_id: payment_id,
      status: status,
      subtotal_cents: subtotal_cents,
      donation_cents: donation_cents,
      total_cents: total_cents
    }
  end

  def total_equals_subtotal_plus_donation
    return if total_cents.nil? || subtotal_cents.nil? || donation_cents.nil?

    expected = subtotal_cents + donation_cents
    return if total_cents == expected

    errors.add(:total_cents, "must equal subtotal_cents plus donation_cents")
  end
end
