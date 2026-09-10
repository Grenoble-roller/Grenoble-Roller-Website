# frozen_string_literal: true

module Orders
  class PaymentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_order

    # POST /orders/:order_id/payments
    def create
      payment = @order.payment

      # CHECK OBLIGATOIRE : Vérifier le statut réel avec HelloAsso AVANT de créer un nouveau checkout-intent
      if payment&.provider == "helloasso" && payment.status == "pending"
        HelloassoService.fetch_and_update_payment(payment)
        @order.reload
        payment.reload
      end

      # Vérifier les conditions APRÈS le check
      order_status = @order.status&.downcase
      is_cancelled = [ "cancelled", "annulé", "canceled" ].include?(order_status)
      is_pending = order_status == "pending"

      # Permettre le paiement si : commande pending + non annulée + (pas de payment OU payment pending helloasso)
      can_pay = is_pending &&
                !is_cancelled &&
                (payment.nil? || (payment.provider == "helloasso" && payment.status == "pending"))

      unless can_pay
        # Si déjà payé, annulé ou autre statut, rediriger vers la liste des commandes à jour
        message = if is_cancelled
          "Cette commande est annulée et ne peut plus être payée."
        else
          "Le statut de cette commande a été mis à jour. " \
          "Statut actuel : #{@order.status} / #{payment&.status || 'pas de paiement'}"
        end
        redirect_to orders_path, notice: message
        return
      end

      # Product Order created by unified Checkout — do not start a legacy product-only intent.
      if @order.open_unified_checkout
        resume_or_redirect_unified_checkout!
        return
      end

      # Créer un nouveau checkout-intent (plus fiable que de réutiliser l'ancien qui peut expirer)
      # Utiliser le don stocké dans l'order
      begin
        checkout_result = HelloassoService.create_checkout_intent(
          @order,
          donation_cents: @order.donation_cents || 0,
          back_url: orders_url,
          error_url: order_url(@order),
          return_url: order_url(@order)
        )
      rescue => e
        Rails.logger.error("[Orders::PaymentsController#create] Erreur lors de la création du checkout-intent : #{e.class} - #{e.message}")

        # Message d'erreur adapté selon le type d'erreur
        error_message = if e.message.include?("429") || e.message.include?("Rate limit")
          "Les serveurs HelloAsso sont temporairement surchargés. " \
          "Merci de réessayer dans quelques minutes."
        elsif e.message.include?("access_token")
          "Erreur de configuration HelloAsso. " \
          "Merci de contacter l'association."
        else
          "Erreur lors de l'initialisation du paiement HelloAsso. " \
          "Merci de réessayer plus tard ou de contacter l'association."
        end

        redirect_to order_path(@order), alert: error_message
        return
      end

      if checkout_result[:success]
        body = checkout_result[:body] || {}
        redirect_url = body["redirectUrl"]

        # Créer ou mettre à jour le payment avec le nouveau checkout-intent ID
        if body["id"].present?
          if payment.nil?
            # Créer un nouveau payment si il n'existe pas
            payment = Payment.create!(
              provider: "helloasso",
              provider_payment_id: body["id"].to_s,
              amount_cents: @order.total_cents,
              currency: "EUR",
              status: "pending",
              created_at: Time.current
            )
            @order.update!(payment: payment)
          else
            # Mettre à jour le payment existant avec le nouveau checkout-intent ID
            payment.update!(
              provider_payment_id: body["id"].to_s
            )
          end
        end

        if redirect_url.present?
          redirect_to redirect_url, allow_other_host: true
        else
          redirect_to order_path(@order),
                      alert: "Impossible de récupérer l'URL de paiement HelloAsso. " \
                             "Merci de réessayer plus tard ou de contacter l'association."
        end
      else
        redirect_to order_path(@order),
                    alert: "Erreur lors de l'initialisation du paiement HelloAsso. " \
                           "Merci de réessayer plus tard ou de contacter l'association."
      end
    end

    # GET /orders/:order_id/payments/status (collection)
    # ou GET /payments/:id (shallow) - mais on utilise la collection pour le statut
    def show
      # Si pas de payment mais commande pending → considérer comme pending
      if @order.payment.nil?
        order_status = @order.status.downcase
        if [ "pending", "en attente" ].include?(order_status)
          render json: { status: "pending" }
          return
        else
          render json: { status: "unknown" }
          return
        end
      end

      # Si le paiement est pending et HelloAsso, faire un check réel
      if @order.payment.provider == "helloasso" && @order.payment.status == "pending"
        HelloassoService.fetch_and_update_payment(@order.payment)
        @order.reload
        @order.payment.reload
      end

      render json: { status: @order.payment.status || "unknown" }
    rescue => e
      Rails.logger.error("[Orders::PaymentsController] Erreur lors de la vérification du statut : #{e.message}")
      render json: { status: "unknown" }, status: 500
    end

    private

    def resume_or_redirect_unified_checkout!
      unified = @order.open_unified_checkout
      payment = unified&.payment || @order.payment

      if payment&.provider == "helloasso" &&
         payment.status == "pending" &&
         payment.provider_payment_id.present?
        redirect_url = HelloassoService.checkout_redirect_url_for_intent(payment.provider_payment_id)
        if redirect_url.present?
          redirect_to redirect_url, allow_other_host: true
          return
        end
      end

      redirect_to new_checkout_path,
                  alert: "Cette commande fait partie d'un panier unifié. " \
                         "Finalisez le paiement depuis le panier."
    end

    def set_order
      @order = current_user.orders.includes(:payment, order_items: :variant).find(params[:order_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to orders_path, alert: "Commande introuvable."
    end
  end
end
