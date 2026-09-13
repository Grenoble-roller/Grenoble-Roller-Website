# frozen_string_literal: true

class CheckoutLine < ApplicationRecord
  belongs_to :checkout
  belongs_to :reference, polymorphic: true

  LABEL_MAX_LENGTH = CartLine::LABEL_MAX_LENGTH

  enum :line_type, {
    product_variant: "product_variant",
    membership: "membership",
    event_registration: "event_registration"
  }, validate: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :label, presence: true, length: { maximum: LABEL_MAX_LENGTH }

  before_update :prevent_mutation_if_checkout_paid

  def subtotal_cents
    amount_cents * quantity
  end

  private

  def prevent_mutation_if_checkout_paid
    return unless checkout&.paid?

    errors.add(:base, "cannot modify checkout line after checkout is paid")
    throw :abort
  end
end
