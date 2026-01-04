# frozen_string_literal: true

module AdminPanel
  class OrdersController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_order, only: %i[show edit update destroy change_status]
    before_action :authorize_order, only: %i[show edit update destroy change_status]

    # GET /admin-panel/orders
    def index
      authorize [ :admin_panel, Order ]

      # Recherche et filtres
      @q = Order.ransack(params[:q])
      @orders = @q.result.includes(:user, :payment, order_items: { variant: :product })

      # Filtres supplémentaires
      @orders = @orders.where(status: params[:status]) if params[:status].present?

      # Pagination
      @pagy, @orders = pagy(@orders.order(created_at: :desc), items: params[:per_page] || 25)

      # Pour les exports
      @all_orders = @q.result if params[:format].present?
    end

    # GET /admin-panel/orders/:id
    def show
      # L'order est déjà chargé via set_order
    end

    # GET /admin-panel/orders/new
    def new
      @order = Order.new
      authorize [ :admin_panel, @order ]
    end

    # POST /admin-panel/orders
    def create
      @order = Order.new(order_params)
      authorize [ :admin_panel, @order ]

      if @order.save
        flash[:notice] = "Commande créée avec succès"
        redirect_to admin_panel_order_path(@order)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/orders/:id/edit
    def edit
      # L'order est déjà chargé via set_order
    end

    # PATCH/PUT /admin-panel/orders/:id
    def update
      if @order.update(order_params)
        flash[:notice] = "Commande mise à jour avec succès"
        redirect_to admin_panel_order_path(@order)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/orders/:id
    def destroy
      if @order.destroy
        flash[:notice] = "Commande supprimée avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@order.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_orders_path
    end

    # PATCH /admin-panel/orders/:id/change_status
    def change_status
      new_status = params[:status]

      if new_status.blank?
        flash[:alert] = "Statut requis"
        redirect_to admin_panel_order_path(@order)
        return
      end

      # TODO: Valider les transitions de statut (PHASE 3)
      if @order.update(status: new_status)
        flash[:notice] = "Statut mis à jour: #{new_status}"
      else
        flash[:alert] = "Erreur lors de la mise à jour: #{@order.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_order_path(@order)
    end

    # GET /admin-panel/orders/export
    def export
      authorize [ :admin_panel, Order ]

      @q = Order.ransack(params[:q])
      @orders = @q.result.includes(:user, :payment, order_items: { variant: :product })

      respond_to do |format|
        format.csv do
          send_data generate_csv, filename: "commandes-#{Date.current}.csv", type: "text/csv"
        end
        format.xlsx do
          # TODO: Implémenter export XLSX avec rubyXL (PHASE 3)
          redirect_to admin_panel_orders_path(format: :csv), alert: "Export XLSX non implémenté (PHASE 3)"
        end
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def authorize_order
      authorize [ :admin_panel, @order ]
    end

    def order_params
      params.require(:order).permit(
        :user_id,
        :status,
        :total_cents,
        :currency,
        :donation_cents
      )
    end

    def generate_csv
      require "csv"

      CSV.generate(headers: true) do |csv|
        # En-têtes
        csv << [
          "ID",
          "Client",
          "Email",
          "Total (€)",
          "Statut",
          "Date création"
        ]

        # Données
        @orders.each do |order|
          csv << [
            order.id,
            order.user&.first_name || order.user&.email || "N/A",
            order.user&.email || "N/A",
            order.total_cents / 100.0,
            order.status,
            order.created_at&.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end
    end
  end
end
