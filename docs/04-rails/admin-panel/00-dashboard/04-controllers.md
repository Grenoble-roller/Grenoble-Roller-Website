# 🎮 CONTROLLERS - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13

---

## 📋 Description

Controller Dashboard et Maintenance.

---

## ✅ Controller 1 : DashboardController ✅ AMÉLIORÉ

**Fichier** : `app/controllers/admin_panel/dashboard_controller.rb`

**Status** : ✅ **AMÉLIORÉ ET FONCTIONNEL** (2025-01-13)

**Code implémenté** :
```ruby
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
    end
  end
end
```

### **Améliorations apportées** :
- ✅ Utilise `AdminDashboardService` pour tous les calculs
- ✅ KPIs avancés (8 indicateurs)
- ✅ Intégration avec Inventories (stock faible/rupture)
- ✅ Intégration avec Orders (CA, ventes par jour)
- ✅ Intégration avec Initiations (à venir)
- ✅ Code propre et maintenable

---

## ✅ Controller 2 : MaintenanceController ✅ CRÉÉ

**Fichier** : `app/controllers/admin_panel/maintenance_controller.rb`

**Status** : ✅ **CRÉÉ ET FONCTIONNEL** (2025-01-13)

**Code implémenté** :
```ruby
# frozen_string_literal: true

module AdminPanel
  class MaintenanceController < BaseController
    before_action :authorize_maintenance, only: [:toggle]

    # PATCH /admin-panel/maintenance/toggle
    def toggle
      user_email = current_user.email

      if MaintenanceMode.enabled?
        MaintenanceMode.disable!
        message = "Mode maintenance DÉSACTIVÉ"
        Rails.logger.info("🔓 MAINTENANCE DÉSACTIVÉE par #{user_email}")
        flash[:notice] = message
      else
        MaintenanceMode.enable!
        message = "Mode maintenance ACTIVÉ"
        Rails.logger.warn("🔒 MAINTENANCE ACTIVÉE par #{user_email}")
        flash[:notice] = message
      end

      redirect_to admin_panel_root_path
    end

    private

    def authorize_maintenance
      # Utiliser un objet symbolique pour Pundit (MaintenanceMode n'est pas un modèle ActiveRecord)
      authorize :maintenance, policy_class: AdminPanel::MaintenancePolicy
    end
  end
end
```

### **Sécurité** :
- ✅ Vérification via `BaseController` (level >= 60)
- ✅ Policy `AdminPanel::MaintenancePolicy` pour double vérification
- ✅ Logging des actions (qui a activé/désactivé)
- ✅ Redirection avec messages flash

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)** ✅ COMPLÉTÉ
- [x] Améliorer DashboardController ✅
- [x] Créer MaintenanceController ✅
- [x] Créer MaintenancePolicy ✅
- [x] Intégrer dans Dashboard ✅
- [x] Tester toutes les actions ✅

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
