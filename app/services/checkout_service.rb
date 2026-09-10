# frozen_string_literal: true

class CheckoutService
  class EmptySelectionError < StandardError; end
  class ExpiredLinesError < StandardError; end
  class ForbiddenError < StandardError; end
  class InsufficientStockError < StandardError; end
  class InvalidLineError < StandardError; end

  class << self
    def build_from_cart(user, cart_line_ids:, donation_cents: 0)
      ids = Array(cart_line_ids).map(&:to_i).reject(&:zero?).uniq
      raise EmptySelectionError if ids.empty?

      donation_cents = [ donation_cents.to_i, 0 ].max
      lines = CartLine.where(id: ids).includes(:reference)

      raise ForbiddenError if lines.any? { |l| l.user_id != user.id }
      raise EmptySelectionError if lines.size != ids.size

      expired = lines.select(&:expired?)
      raise ExpiredLinesError, expired.map(&:label).join(", ") if expired.any?

      validate_lines!(lines)

      subtotal_cents = lines.sum(&:subtotal_cents)
      total_cents = subtotal_cents + donation_cents

      checkout = nil
      Checkout.transaction do
        checkout = Checkout.create!(
          user: user,
          status: :pending,
          subtotal_cents: subtotal_cents,
          donation_cents: donation_cents,
          total_cents: total_cents,
          metadata: { "selected_line_ids" => ids }
        )

        product_lines = lines.select(&:product_variant?)
        order = create_product_order!(user, checkout, product_lines, donation_cents) if product_lines.any?

        lines.each do |cart_line|
          line_metadata = (cart_line.metadata || {}).dup
          line_metadata["order_id"] = order.id if order && cart_line.product_variant?

          CheckoutLine.create!(
            checkout: checkout,
            cart_line_id: cart_line.id,
            line_type: cart_line.line_type,
            reference: cart_line.reference,
            amount_cents: cart_line.amount_cents,
            label: CartLineService.truncate_cart_label(cart_line.label),
            quantity: cart_line.quantity,
            metadata: line_metadata
          )
        end

        checkout.update!(metadata: checkout.metadata.merge("order_id" => order.id)) if order
      end

      checkout.reload
    end

    private

    def validate_lines!(lines)
      lines.each do |line|
        case line.line_type
        when "product_variant"
          validate_product_line!(line)
        when "membership"
          validate_membership_line!(line)
        when "event_registration"
          validate_event_line!(line)
        end
      end
    end

    def validate_product_line!(line)
      variant = line.reference
      raise InvalidLineError, "Product unavailable" unless variant&.is_active && variant.product&.is_active

      available = CartLineService.available_stock_for(variant)
      raise InsufficientStockError, line.label if available < line.quantity
    end

    def validate_membership_line!(line)
      membership = line.reference
      raise InvalidLineError, "Membership not pending" unless membership&.pending?
      raise InvalidLineError, "Health questionnaire incomplete" unless membership.health_questionnaire_complete?
    end

    def validate_event_line!(line)
      attendance = line.reference
      raise InvalidLineError, "Attendance hold expired" unless attendance&.payment_pending?
    end

    def create_product_order!(user, checkout, product_lines, donation_cents)
      product_subtotal = product_lines.sum(&:subtotal_cents)

      order = Order.create!(
        user: user,
        status: "pending",
        total_cents: product_subtotal,
        donation_cents: 0,
        currency: "EUR"
      )

      product_lines.each do |cart_line|
        variant = cart_line.reference
        OrderItem.create!(
          order: order,
          variant_id: variant.id,
          quantity: cart_line.quantity,
          unit_price_cents: cart_line.amount_cents
        )
      end

      order
    end
  end
end
