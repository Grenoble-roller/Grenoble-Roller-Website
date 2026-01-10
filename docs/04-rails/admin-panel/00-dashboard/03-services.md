# 🔧 SERVICES - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13

---

## 📋 Description

Service pour calculer les KPIs et statistiques du dashboard.

---

## ✅ Service : AdminDashboardService ✅ CRÉÉ

**Fichier** : `app/services/admin_dashboard_service.rb`

**Status** : ✅ **IMPLÉMENTÉ ET TESTÉ** (2025-01-13)

**Code implémenté** :
```ruby
# frozen_string_literal: true

# Service pour calculer les KPIs et statistiques du dashboard admin
class AdminDashboardService
  # Retourne tous les KPIs principaux
  def self.kpis
    {
      users: User.count,
      products: Product.count,
      active_products: Product.where(is_active: true).count,
      orders: Order.count,
      pending_orders: Order.where(status: 'pending').count,
      paid_orders: Order.where(status: 'paid').count,
      shipped_orders: Order.where(status: 'shipped').count,
      revenue: calculate_revenue,
      low_stock: calculate_low_stock,
      out_of_stock: calculate_out_of_stock
    }
  end

  # Retourne les commandes récentes
  def self.recent_orders(limit = 10)
    Order.includes(:user, :payment).order(created_at: :desc).limit(limit)
  end

  # Retourne les initiations à venir
  def self.upcoming_initiations(limit = 5)
    return [] unless defined?(Event::Initiation)

    Event::Initiation.upcoming_initiations.published.limit(limit)
  rescue StandardError => e
    Rails.logger.error("Erreur lors de la récupération des initiations : #{e.message}")
    []
  end

  # Retourne les ventes par jour pour les N derniers jours
  def self.sales_by_day(days = 7)
    orders = Order
             .where(status: ['paid', 'shipped'])
             .where('created_at >= ?', days.days.ago)
             .select('DATE(created_at) as sale_date, SUM(total_cents) as total_cents')
             .group('DATE(created_at)')
             .order('sale_date ASC')

    # Transformer en hash { date => montant }
    sales_hash = {}
    orders.each do |order|
      date = order.sale_date.to_date
      sales_hash[date] = (order.total_cents.to_f / 100.0)
    end

    # Remplir les jours manquants avec 0
    (days.days.ago.to_date..Date.current).each do |date|
      sales_hash[date] ||= 0.0
    end

    sales_hash.sort.to_h
  end

  private

  # Calcule le CA total (commandes payées ou expédiées)
  def self.calculate_revenue
    Order.where(status: ['paid', 'shipped']).sum(:total_cents) / 100.0
  end

  # Calcule le nombre de produits en stock faible (<= 10 unités disponibles)
  def self.calculate_low_stock
    return 0 unless defined?(Inventory)

    ProductVariant
      .joins(:inventory)
      .where('inventories.available_qty <= ?', 10)
      .where(is_active: true)
      .where('inventories.available_qty > 0')
      .count
  rescue StandardError => e
    Rails.logger.error("Erreur lors du calcul du stock faible : #{e.message}")
    0
  end

  # Calcule le nombre de produits en rupture de stock (0 unité disponible)
  def self.calculate_out_of_stock
    return 0 unless defined?(Inventory)

    ProductVariant
      .joins(:inventory)
      .where('inventories.available_qty <= 0')
      .where(is_active: true)
      .count
  rescue StandardError => e
    Rails.logger.error("Erreur lors du calcul de la rupture de stock : #{e.message}")
    0
  end
end
```

### **Méthodes disponibles** :
- `kpis` : Retourne tous les KPIs (utilisateurs, produits, commandes, CA, stock)
- `recent_orders(limit)` : Commandes récentes avec eager loading
- `upcoming_initiations(limit)` : Initiations à venir (gestion d'erreurs)
- `sales_by_day(days)` : Ventes par jour avec remplissage des jours manquants

### **Gestion d'erreurs** :
- Gestion des erreurs pour les initiations (si non disponibles)
- Gestion des erreurs pour le stock (si Inventories non disponible)
- Logging des erreurs pour debugging

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)** ✅ COMPLÉTÉ
- [x] Créer AdminDashboardService ✅
- [x] Implémenter méthodes KPIs ✅
- [x] Tester calculs ✅
- [x] Intégrer avec Inventories ✅
- [x] Intégrer avec Orders ✅
- [x] Intégrer avec Initiations ✅

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
