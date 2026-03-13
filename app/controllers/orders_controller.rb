class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ] # Exiger confirmation pour passer une commande

  # Vérification explicite de la confirmation email pour create (même en test)
  def ensure_email_confirmed
    return true unless user_signed_in?

    # Recharger l'utilisateur depuis la DB pour éviter les problèmes de cache
    # Utiliser current_user.id directement pour éviter les problèmes de cache
    user_id = current_user.id
    user = User.find(user_id)

    # Vérifier confirmed_at directement (pas confirmed? qui peut être mis en cache)
    unless user.confirmed_at.present?
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path,
        class: "alert-link"
      )
      redirect_to root_path,
                  alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                         "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe
      return false # Arrêter l'exécution du callback (alternative à throw(:abort))
    end
    true
  end

  def index
    @orders = current_user.orders.includes(:payment, order_items: { variant: :product }).order(created_at: :desc)
  end

  def new
    @cart_items = build_cart_items
    redirect_to cart_path, alert: "Votre panier est vide." and return if @cart_items.empty?
    @total_cents = @cart_items.sum { |ci| ci[:subtotal_cents] }
  end

  def create
    # Double vérification de la confirmation email (en plus du callback)
    # Recharger l'utilisateur depuis la DB pour éviter les problèmes de cache
    # Utiliser current_user.id directement pour éviter les problèmes de cache
    user_id = current_user.id
    user = User.find(user_id)

    # Vérifier confirmed_at directement (pas confirmed? qui peut être mis en cache)
    unless user.confirmed_at.present?
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path,
        class: "alert-link"
      )
      return redirect_to root_path,
                    alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                           "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe
    end

    cart_items = build_cart_items
    return redirect_to cart_path, alert: "Votre panier est vide." if cart_items.empty?

    # Vérifier le stock avant de créer la commande
    # Utilise le système Inventories (available_qty = stock_qty - reserved_qty)
    stock_errors = []
    cart_items.each do |ci|
      variant = ci[:variant]
      requested_qty = ci[:quantity]
      # Utiliser inventory.available_qty si disponible, sinon fallback sur stock_qty
      available_stock = if variant.inventory
                          variant.inventory.available_qty
      else
                          variant.stock_qty.to_i
      end

      if !variant.is_active || !variant.product&.is_active
        stock_errors << "#{variant.product.name} (#{variant.sku}) n'est plus disponible"
      elsif available_stock < requested_qty
        stock_errors << "#{variant.product.name} (#{variant.sku}) : stock insuffisant (#{requested_qty} demandé, #{available_stock} disponible)"
      end
    end

    if stock_errors.any?
      return redirect_to cart_path, alert: "Stock insuffisant : #{stock_errors.join('; ')}"
    end

    total_cents = cart_items.sum { |ci| ci[:subtotal_cents] }

    # Récupérer le don (en centimes) depuis les params
    donation_cents = params[:donation_cents].to_i
    donation_cents = 0 if donation_cents < 0 # Sécurité : pas de don négatif

    # Le total de la commande inclut le don
    order_total_cents = total_cents + donation_cents

    # Transaction pour garantir la cohérence des données locales (order + stock)
    order = Order.transaction do
      order = Order.create!(
        user: current_user,
        status: "pending",
        total_cents: order_total_cents, # Total inclut le don
        donation_cents: donation_cents, # Stocker le don séparément
        currency: "EUR"
      )

      # Envoyer l'email de confirmation de commande (après création)
      OrderMailer.order_confirmation(order).deliver_later

      cart_items.each do |ci|
        variant = ci[:variant]
        OrderItem.create!(
          order: order,
          variant_id: variant.id,
          quantity: ci[:quantity],
          unit_price_cents: ci[:unit_price_cents]
        )

        # Le stock sera réservé automatiquement via le callback after_create :reserve_stock dans Order
        # Plus besoin de décrementer manuellement stock_qty
      end
      order
    end

    # Vider le panier local une fois la commande créée
    session[:cart] = {}

    # Initialiser un checkout HelloAsso avec le don
    checkout_result = HelloassoService.create_checkout_intent(
      order,
      donation_cents: donation_cents,
      back_url: shop_url,
      error_url: order_url(order),
      return_url: order_url(order)
    )

    if checkout_result[:success]
      body = checkout_result[:body] || {}

      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: body["id"].to_s,
        amount_cents: order_total_cents, # Montant total inclut le don
        currency: "EUR",
        status: "pending",
        created_at: Time.current
      )

      order.update!(payment: payment)

      redirect_url = body["redirectUrl"]

      if redirect_url.present?
        # URL externe (HelloAsso sandbox/production) → autoriser l'hôte externe explicitement
        redirect_to redirect_url, allow_other_host: true
      else
        redirect_to order_path(order), notice: "Commande créée avec succès (paiement HelloAsso initialisé)."
      end
    else
      # Fallback : si HelloAsso ne renvoie pas d'URL ou renvoie une erreur,
      # on garde la commande en pending et on affiche un message.
      redirect_to order_path(order), alert: "Commande créée mais paiement HelloAsso non initialisé (code #{checkout_result[:status]})."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to cart_path, alert: "Erreur lors de la création de la commande: #{e.message}"
  rescue => e
    redirect_to cart_path, alert: "Erreur : #{e.message}"
  end

  def show
    # Support hashid ou ID numérique
    # D'abord trouver l'order par hashid ou ID (sans scope pour hashid)
    found_order = Order.find_by_hashid(params[:id]) if params[:id].present?
    found_order ||= Order.find_by(id: params[:id]) if params[:id].present? && params[:id].match?(/\A\d+\z/)

    # Vérifier que l'order appartient à l'utilisateur
    if found_order && found_order.user_id == current_user.id
      order_scope = current_user.orders.includes(:payment, order_items: { variant: :product })
      @order = order_scope.find(found_order.id)
    else
      # Si l'order n'existe pas ou n'appartient pas à l'utilisateur, lever RecordNotFound
      raise ActiveRecord::RecordNotFound, "Couldn't find Order with 'id'=#{params[:id]}"
    end
  end

  def check_payment
    @order = current_user.orders.includes(:payment).find(params[:id])

    if @order.payment&.provider == "helloasso"
      HelloassoService.fetch_and_update_payment(@order.payment)
      @order.reload
      redirect_to order_path(@order), notice: "✅ Vérification du paiement effectuée"
    else
      redirect_to order_path(@order), alert: "Aucun paiement associé à cette commande."
    end
  end


  def cancel
    @order = current_user.orders.includes(:payment, order_items: :variant).find(params[:id])

    # CHECK OBLIGATOIRE : Si la commande est payée via HelloAsso, vérifier le statut réel
    if @order.payment&.provider == "helloasso" && @order.payment.status != "pending"
      HelloassoService.fetch_and_update_payment(@order.payment)
      @order.reload
    end

    # Vérifier que la commande peut être annulée
    unless [ "pending", "en attente", "preparation", "en préparation", "preparing" ].include?(@order.status.downcase)
      if @order.status.downcase == "paid" || @order.status.downcase == "payé"
        redirect_to order_path(@order),
                    alert: "Cette commande est déjà payée. " \
                           "Pour un remboursement, veuillez contacter l'association. " \
                           "Le remboursement sera effectué manuellement."
      else
        redirect_to order_path(@order), alert: "Cette commande ne peut pas être annulée."
      end
      return
    end

    # Transaction pour garantir la cohérence
    Order.transaction do
      # Le stock sera libéré automatiquement via le callback handle_stock_on_status_change
      # lors du changement de statut vers "cancelled"
      # Plus besoin de restaurer manuellement le stock

      # Mettre à jour le statut (le callback va gérer la libération du stock réservé)
      @order.update!(status: "cancelled")
    end

    redirect_to order_path(@order), notice: "Commande annulée avec succès."
  rescue => e
    redirect_to order_path(@order), alert: "Erreur lors de l'annulation : #{e.message}"
  end

  private

  def build_cart_items
    session[:cart] ||= {}
    variant_ids = session[:cart].keys
    return [] if variant_ids.empty?
    variants = ProductVariant.where(id: variant_ids).includes(:product, :inventory).index_by { |v| v.id.to_s }
    session[:cart].map do |vid, qty|
      variant = variants[vid.to_s]
      next nil unless variant
      price_cents = variant.price_cents
      {
        variant: variant,
        product: variant.product,
        quantity: qty.to_i,
        unit_price_cents: price_cents,
        subtotal_cents: price_cents * qty.to_i
      }
    end.compact
  end
end
