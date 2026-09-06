class Payment < ApplicationRecord
  include Auditable

  has_many :orders, dependent: :nullify
  has_many :checkouts, dependent: :nullify
  has_many :attendances, dependent: :nullify
  has_one :membership, dependent: :nullify
  has_many :memberships, dependent: :nullify

  scope :pending_helloasso, lambda {
    where(provider: "helloasso", status: "pending")
      .where("created_at > ?", 24.hours.ago)
  }

  def self.check_and_update_helloasso_orders
    pending_helloasso.find_each do |payment|
      HelloassoService.fetch_and_update_payment(payment)
    rescue StandardError => e
      Rails.logger.error(
        "[Payment] Polling HelloAsso failed for payment ##{payment.id}: " \
        "#{e.class} - #{e.message}"
      )
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id amount_cents created_at updated_at currency provider provider_payment_id status]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[orders memberships attendances]
  end

  private

  def audit_actor
    nil
  end

  def audit_attributes
    {
      amount_cents: amount_cents,
      currency: currency,
      provider: provider,
      status: status
    }
  end
end
