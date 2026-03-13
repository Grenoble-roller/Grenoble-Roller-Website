# frozen_string_literal: true

module AdminPanel
  module OrdersHelper
    # Badge pour le statut de la commande (accepte order ou status string)
    # Libellé via I18n (statuses.order.*)
    def status_badge(order_or_status)
      status = order_or_status.is_a?(String) ? order_or_status : order_or_status.status
      status_text = human_status(:order, status)
      css = case status.to_s
      when "pending" then "badge-liquid-warning"
      when "paid" then "badge-liquid-success"
      when "preparation" then "badge-liquid-primary"
      when "shipped" then "badge-liquid-success"
      when "cancelled", "canceled" then "badge-liquid-danger"
      when "refund_requested" then "badge-liquid-warning"
      when "refunded" then "badge-liquid-secondary"
      when "failed" then "badge-liquid-danger"
      else "badge-liquid-secondary"
      end
      content_tag(:span, status_text, class: "badge #{css}")
    end

    # Affichage du montant total formaté
    def total_display(order)
      number_to_currency(order.total_cents / 100.0, unit: order.currency == "EUR" ? "€" : order.currency, separator: ",", delimiter: " ")
    end
  end
end
