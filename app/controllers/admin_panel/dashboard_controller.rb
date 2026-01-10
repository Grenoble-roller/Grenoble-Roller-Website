# frozen_string_literal: true

module AdminPanel
  class DashboardController < BaseController
    def index
      # KPIs Principaux (via service)
      kpis = AdminDashboardService.kpis
      @stats = {
        total_users: kpis[:users],
        total_products: kpis[:products],
        active_products: kpis[:active_products],
        total_orders: kpis[:orders],
        pending_orders: kpis[:pending_orders],
        paid_orders: kpis[:paid_orders],
        shipped_orders: kpis[:shipped_orders],
        total_revenue: kpis[:revenue]
      }

      # Stock (via service)
      @low_stock_count = kpis[:low_stock]
      @out_of_stock_count = kpis[:out_of_stock]

      # Initiations à venir (via service)
      @upcoming_initiations = AdminDashboardService.upcoming_initiations(5)

      # Commandes récentes (via service)
      @recent_orders = AdminDashboardService.recent_orders(10)

      # Ventes par jour (7 derniers jours, via service)
      @sales_by_day = AdminDashboardService.sales_by_day(7)

      # Mode Maintenance (statut uniquement, pour affichage)
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level 60 = ADMIN, Level 70 = SUPERADMIN
      @maintenance_enabled = MaintenanceMode.enabled?
      user_level = current_user&.role&.level.to_i
      @can_toggle_maintenance = user_level >= 60
    end
  end
end
