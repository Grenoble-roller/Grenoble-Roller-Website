# frozen_string_literal: true

module AdminPanel
  module OrdersHelper
    # Badge pour le statut de la commande (accepte order ou status string)
    # Helper pour générer un badge avec style liquid glass
    def status_badge(order_or_status)
      status = order_or_status.is_a?(String) ? order_or_status : order_or_status.status
      case status
      when "pending"
        content_tag(:span, "En attente", class: "badge badge-liquid-warning")
      when "paid"
        content_tag(:span, "Payée", class: "badge badge-liquid-success")
      when "preparation"
        content_tag(:span, "En préparation", class: "badge badge-liquid-primary")
      when "shipped"
        content_tag(:span, "Expédiée", class: "badge badge-liquid-success")
      when "cancelled", "canceled"
        content_tag(:span, "Annulée", class: "badge badge-liquid-danger")
      when "refund_requested"
        content_tag(:span, "Remboursement demandé", class: "badge badge-liquid-warning")
      when "refunded"
        content_tag(:span, "Remboursée", class: "badge badge-liquid-secondary")
      when "failed"
        content_tag(:span, "Échouée", class: "badge badge-liquid-danger")
      else
        order = order_or_status.is_a?(String) ? nil : order_or_status
        status_text = order ? order.status.humanize : status.to_s.humanize
        content_tag(:span, status_text, class: "badge badge-liquid-secondary")
      end
    end

    # Affichage du montant total formaté
    def total_display(order)
      number_to_currency(order.total_cents / 100.0, unit: order.currency == "EUR" ? "€" : order.currency, separator: ",", delimiter: " ")
    end
  end
end
