# frozen_string_literal: true

module AdminPanel
  class InventoryController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :authorize_inventory

    # GET /admin-panel/inventory
    def index
      # Stock faible (<= 10) - Calcul: stock_qty - reserved_qty
      @low_stock = ProductVariant
        .joins(:inventory)
        .where("(inventories.stock_qty - inventories.reserved_qty) <= ?", 10)
        .where(is_active: true)
        .order(Arel.sql("(inventories.stock_qty - inventories.reserved_qty) ASC"))
        .includes(:product, :inventory)

      # Rupture de stock (0) - Calcul: stock_qty - reserved_qty
      @out_of_stock = ProductVariant
        .joins(:inventory)
        .where("(inventories.stock_qty - inventories.reserved_qty) <= 0")
        .where(is_active: true)
        .includes(:product, :inventory)

      # Mouvements récents
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user, inventory: :product_variant)
        .limit(50)
    end

    # GET /admin-panel/inventory/transfers
    def transfers
      @q = InventoryMovement.ransack(params[:q])
      @movements = @q.result
        .recent
        .includes(:inventory, :user, inventory: :product_variant)

      @pagy, @movements = pagy(@movements, items: 25)
    end

    # PATCH /admin-panel/inventory/adjust_stock
    def adjust_stock
      variant = ProductVariant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      reason = params[:reason]
      reference = params[:reference]

      if quantity == 0
        flash[:alert] = "Quantité invalide"
        redirect_back(fallback_location: admin_panel_inventory_path)
        return
      end

      InventoryService.move_stock(variant, quantity, reason, reference)

      flash[:notice] = "Stock ajusté avec succès"
      redirect_back(fallback_location: admin_panel_inventory_path)
    end

    private

    def authorize_inventory
      authorize [ :admin_panel, Inventory ]
    end
  end
end
