# frozen_string_literal: true

class CartLineService
  class InactiveVariantError < StandardError; end
  class NotFoundError < StandardError; end
  class UnauthorizedError < StandardError; end
  class HealthQuestionnaireIncompleteError < StandardError; end
  class InvalidMembershipStatusError < StandardError; end

  EVENT_HOLD_DURATION = 15.minutes

  class << self
    def add_product!(user:, variant:, quantity: 1)
      raise InactiveVariantError unless variant&.is_active && variant.product&.is_active

      available = available_stock_for(variant)
      line = user.cart_lines.find_or_initialize_by(
        line_type: :product_variant,
        reference: variant
      )
      requested = (line.persisted? ? line.quantity : 0) + quantity
      line.quantity = [ requested, available ].min
      line.amount_cents = variant.price_cents
      line.label = truncate_cart_label(variant.product.name)
      line.expires_at = nil
      line.metadata = line.metadata.presence || {}
      line.save!
      line
    end

    def update_product_quantity!(user, variant:, quantity:)
      raise InactiveVariantError unless variant&.is_active && variant.product&.is_active

      line = user.cart_lines.find_by(line_type: :product_variant, reference: variant)
      if quantity <= 0
        line&.destroy!
        return nil
      end

      max_qty = available_stock_for(variant)
      new_qty = [ quantity, max_qty ].min
      if line
        line.update!(quantity: new_qty)
        line
      else
        add_product!(user: user, variant: variant, quantity: new_qty)
      end
    end

    def remove!(user, cart_line_id:)
      line = CartLine.find_by(id: cart_line_id)
      raise NotFoundError unless line
      raise UnauthorizedError unless line.user_id == user.id

      if line.event_registration?
        release_event_line!(line)
      else
        line.destroy!
      end
    end

    def clear!(user)
      user.cart_lines.find_each do |line|
        if line.event_registration?
          release_event_line!(line)
        else
          line.destroy
        end
      end
    end

    def available_stock_for(variant)
      variant.inventory&.available_qty || variant.stock_qty.to_i
    end

    def list(user, include_expired: false)
      scope = user.cart_lines.ordered_by_created
      scope = scope.active unless include_expired
      scope.includes(reference: :product).to_a
    end

    def event_lines(user)
      list(user, include_expired: false).select(&:event_registration?)
    end

    def total_cents(user, include_expired: false)
      list(user, include_expired: include_expired).sum(&:subtotal_cents)
    end

    def count(user, include_expired: false)
      list(user, include_expired: include_expired).size
    end

    # Re-sync pending membership cart lines (season/amount/label).
    # Drop stale lines when the membership is no longer pending (paid, cancelled, etc.).
    def refresh_membership_lines!(user)
      user.cart_lines.membership.active.includes(:reference).find_each do |line|
        membership = line.reference
        unless membership.is_a?(Membership)
          line.destroy
          next
        end

        unless membership.pending?
          line.destroy
          next
        end

        next unless membership.health_questionnaire_complete?

        add_membership!(user, membership: membership)
      end
    end

    def add_membership!(user, membership:)
      raise HealthQuestionnaireIncompleteError unless membership.health_questionnaire_complete?
      unless membership.pending?
        raise InvalidMembershipStatusError, "Only pending memberships can be added to the cart."
      end

      membership.align_to_sale_season!
      membership.reload

      metadata = { "season" => membership.season }
      metadata["child_name"] = membership.child_full_name if membership.is_child_membership?

      user.cart_lines.find_or_initialize_by(
        line_type: :membership,
        reference: membership
      ).tap do |line|
        line.amount_cents = membership.total_amount_cents
        line.label = truncate_cart_label(membership_cart_label(membership))
        line.quantity = 1
        line.expires_at = nil
        line.metadata = metadata
        line.save!
      end
    end

    def membership_in_cart?(user, membership)
      user.cart_lines.membership.active.exists?(reference: membership)
    end

    def add_event_registration!(user:, attendance:, event:)
      expires_at = EVENT_HOLD_DURATION.from_now
      label = truncate_cart_label("#{event.title} — #{attendance.participant_name}")

      user.cart_lines.find_or_initialize_by(
        line_type: :event_registration,
        reference: attendance
      ).tap do |line|
        line.amount_cents = event.price_cents
        line.label = label
        line.quantity = 1
        line.expires_at = expires_at
        line.metadata = (line.metadata || {}).merge(
          "event_id" => event.id,
          "attendance_id" => attendance.id
        )
        line.save!
      end
    end

    def release_event_line!(cart_line)
      return unless cart_line.event_registration?

      attendance = cart_line.reference
      cart_line.destroy!
      if attendance.is_a?(Attendance) && attendance.pending? && attendance.payment_expires_at.present?
        attendance.destroy
      end
    end

    def expire_stale!(user = nil)
      scope = CartLine.expired
      scope = scope.where(user: user) if user

      scope.find_each do |line|
        if line.event_registration?
          release_event_line!(line)
        else
          line.destroy
        end
      end
    end

    def truncate_cart_label(label)
      text = label.to_s
      return text if text.length <= CartLine::LABEL_MAX_LENGTH

      "#{text[0, CartLine::LABEL_MAX_LENGTH - 1]}…"
    end

    private

    def membership_cart_label(membership)
      base = membership.with_ffrs? ? "Cotisation + Licence FFRS" : "Cotisation Adhérent Grenoble Roller"
      label = "#{base} — Saison #{membership.season}"
      label = "#{label} (#{membership.child_full_name})" if membership.is_child_membership?
      label
    end
  end
end
