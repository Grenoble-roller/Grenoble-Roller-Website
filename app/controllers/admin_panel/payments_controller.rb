# frozen_string_literal: true

module AdminPanel
  class PaymentsController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_payment, only: %i[show destroy]
    before_action :authorize_payment, only: %i[show destroy]

    # GET /admin-panel/payments
    def index
      authorize [ :admin_panel, Payment ]

      # Recherche et filtres Ransack
      @q = Payment.ransack(params[:q])
      @payments = @q.result.includes(:orders, :memberships, :attendances)

      # Pagination
      @pagy, @payments = pagy(@payments.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/payments/:id
    def show
      # Le payment est déjà chargé via set_payment
      @orders = @payment.orders.includes(:user, order_items: { variant: :product })
      @memberships = @payment.memberships.includes(:user)
      @attendances = @payment.attendances.includes(:user, :event)
    end

    # DELETE /admin-panel/payments/:id
    def destroy
      if @payment.destroy
        flash[:notice] = "Le paiement ##{@payment.id} a été supprimé avec succès."
        redirect_to admin_panel_payments_path
      else
        flash[:alert] = "Impossible de supprimer le paiement : #{@payment.errors.full_messages.join(', ')}"
        redirect_to admin_panel_payment_path(@payment)
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end

    def authorize_payment
      authorize [ :admin_panel, @payment ]
    end
  end
end
