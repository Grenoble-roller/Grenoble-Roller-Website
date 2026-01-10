class Order < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :payment, optional: true  # Optionnel pour l'instant, sera requis avec HelloAsso
  has_many :order_items, dependent: :destroy

  # Statuts possibles pour les commandes
  # pending: En attente de paiement
  # paid: Payée
  # preparation: En préparation
  # shipped: Expédiée
  # cancelled: Annulée
  # refund_requested: Demande de remboursement en cours
  # refunded: Remboursée
  # failed: Échouée (paiement refusé)

  # Callbacks pour gérer le stock et les notifications
  after_commit :reserve_stock, on: :create  # NOUVEAU : Réserver le stock à la création (après commit pour avoir les order_items)
  before_update :handle_stock_on_status_change, if: :will_save_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id payment_id status total_cents currency created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user payment order_items]
  end

  private

  # NOUVEAU : Réserver le stock à la création de la commande
  # Le stock est réservé (reserved_qty) mais pas encore déduit (stock_qty)
  def reserve_stock
    return unless status == "pending"

    order_items.includes(variant: :inventory).each do |item|
      variant = item.variant
      next unless variant&.inventory

      variant.inventory.reserve_stock(item.quantity, id, user)
    end
  end

  # AMÉLIORÉ : Gérer le stock selon le changement de statut
  # Utilise le système Inventories (reserve/release/move_stock)
  def handle_stock_on_status_change
    previous_status = status_was || attribute_was(:status)
    current_status = status

    return unless previous_status.present? && previous_status != current_status

    # Précharger les order_items avec leurs variants et inventaires
    items = order_items.includes(variant: :inventory).to_a

    case current_status
    when "paid", "preparation"
      # Stock déjà réservé, rien à faire
      # Le stock reste réservé jusqu'à l'expédition

    when "shipped"
      # Déduire définitivement du stock et libérer la réservation
      items.each do |item|
        variant = item.variant
        next unless variant&.inventory

        # Déduire du stock réel (stock_qty)
        variant.inventory.move_stock(-item.quantity, "order_fulfilled", id.to_s, user)
        # Libérer la réservation (reserved_qty)
        variant.inventory.release_stock(item.quantity, id, user)
      end

    when "cancelled", "refunded"
      # Libérer le stock réservé (sans déduire du stock réel car pas encore expédié)
      items.each do |item|
        variant = item.variant
        next unless variant&.inventory

        variant.inventory.release_stock(item.quantity, id, user)
      end
    end
  end

  # Envoie un email de notification lors d'un changement de statut
  def notify_status_change
    previous_status = attribute_was(:status) || status_before_last_save
    current_status = status

    # Ne pas envoyer d'email si c'est la création initiale (pas de previous_status)
    return unless previous_status.present? && previous_status != current_status

    case current_status
    when "paid", "payé"
      OrderMailer.order_paid(self).deliver_later
    when "cancelled", "annulé"
      OrderMailer.order_cancelled(self).deliver_later
    when "preparation", "en préparation", "preparing"
      OrderMailer.order_preparation(self).deliver_later
    when "shipped", "envoyé", "expédié"
      OrderMailer.order_shipped(self).deliver_later
    when "refund_requested", "remboursement_demandé"
      OrderMailer.refund_requested(self).deliver_later
    when "refunded", "remboursé"
      OrderMailer.refund_confirmed(self).deliver_later
    end
  end
end

# chaque commande (Order) appartient à un utilisateur (User).
# chaque commande est liée à un paiement précis
# chaque commande contient plusieurs articles de commande
