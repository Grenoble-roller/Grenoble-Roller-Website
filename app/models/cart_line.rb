# frozen_string_literal: true

class CartLine < ApplicationRecord
  include Auditable

  belongs_to :user
  belongs_to :reference, polymorphic: true

  enum :line_type, {
    product_variant: "product_variant",
    membership: "membership",
    event_registration: "event_registration"
  }, validate: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :label, presence: true
  validates :reference_id, uniqueness: {
    scope: [ :user_id, :reference_type, :line_type ],
    message: "already in cart for this user"
  }

  scope :for_user, ->(user) { where(user: user) }
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :ordered_by_created, -> { order(:created_at) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def subtotal_cents
    amount_cents * quantity
  end

  private

  def audit_actor
    user
  end

  def audit_attributes
    {
      user_id: user_id,
      reference_type: reference_type,
      reference_id: reference_id,
      line_type: line_type,
      amount_cents: amount_cents,
      quantity: quantity,
      label: label
    }
  end
end
