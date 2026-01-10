# 📊 TABLEAU DE BORD - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13  
**Statut** : ✅ **AMÉLIORÉ ET FONCTIONNEL**

---

## 📋 Description

Tableau de bord principal de l'Admin Panel avec KPIs, statistiques et vue d'ensemble de l'activité.

**Fichiers** : 
- `app/services/admin_dashboard_service.rb` ✅ **CRÉÉ**
- `app/controllers/admin_panel/dashboard_controller.rb` ✅ **AMÉLIORÉ**
- `app/views/admin_panel/dashboard/index.html.erb` ✅ **AMÉLIORÉE**

---

## 🔧 Améliorations à Apporter

### **1. Controller DashboardController**

**Fichier** : `app/controllers/admin_panel/dashboard_controller.rb`

**Améliorations** :
```ruby
module AdminPanel
  class DashboardController < BaseController
    def index
      # KPIs Principaux
      @stats = {
        total_users: User.count,
        total_products: Product.count,
        active_products: Product.where(is_active: true).count,
        total_orders: Order.count,
        pending_orders: Order.where(status: 'pending').count,
        paid_orders: Order.where(status: 'paid').count,
        shipped_orders: Order.where(status: 'shipped').count,
        total_revenue: Order.where(status: ['paid', 'shipped']).sum(:total_cents) / 100.0
      }
      
      # Stock (nécessite Inventories)
      if defined?(Inventory)
        @low_stock_count = ProductVariant
          .joins(:inventory)
          .where('inventories.available_qty <= ?', 10)
          .where(is_active: true)
          .count
        
        @out_of_stock_count = ProductVariant
          .joins(:inventory)
          .where('inventories.available_qty <= 0')
          .where(is_active: true)
          .count
      else
        @low_stock_count = 0
        @out_of_stock_count = 0
      end
      
      # Initiations à venir
      @upcoming_initiations = Event::Initiation
        .upcoming_initiations
        .published
        .limit(5)
      
      # Commandes récentes
      @recent_orders = Order
        .includes(:user)
        .order(created_at: :desc)
        .limit(10)
      
      # Ventes par jour (7 derniers jours)
      @sales_by_day = Order
        .where(status: ['paid', 'shipped'])
        .where('created_at >= ?', 7.days.ago)
        .group_by_day(:created_at)
        .sum(:total_cents)
        .transform_values { |v| v / 100.0 }
    end
  end
end
```

---

### **2. Service AdminDashboardService**

**Fichier** : `app/services/admin_dashboard_service.rb`

```ruby
class AdminDashboardService
  def self.kpis
    {
      users: User.count,
      products: Product.count,
      active_products: Product.where(is_active: true).count,
      orders: Order.count,
      pending_orders: Order.where(status: 'pending').count,
      revenue: calculate_revenue,
      low_stock: calculate_low_stock,
      out_of_stock: calculate_out_of_stock
    }
  end
  
  def self.recent_orders(limit = 10)
    Order.includes(:user).order(created_at: :desc).limit(limit)
  end
  
  def self.upcoming_initiations(limit = 5)
    Event::Initiation.upcoming_initiations.published.limit(limit)
  end
  
  def self.sales_by_day(days = 7)
    Order
      .where(status: ['paid', 'shipped'])
      .where('created_at >= ?', days.days.ago)
      .group_by_day(:created_at)
      .sum(:total_cents)
      .transform_values { |v| v / 100.0 }
  end
  
  private
  
  def self.calculate_revenue
    Order.where(status: ['paid', 'shipped']).sum(:total_cents) / 100.0
  end
  
  def self.calculate_low_stock
    return 0 unless defined?(Inventory)
    ProductVariant
      .joins(:inventory)
      .where('inventories.available_qty <= ?', 10)
      .where(is_active: true)
      .count
  end
  
  def self.calculate_out_of_stock
    return 0 unless defined?(Inventory)
    ProductVariant
      .joins(:inventory)
      .where('inventories.available_qty <= 0')
      .where(is_active: true)
      .count
  end
end
```

---

### **3. Vue Dashboard Améliorée**

**Fichier** : `app/views/admin_panel/dashboard/index.html.erb`

```erb
<div class="admin-dashboard">
  <!-- HEADER -->
  <div class="mb-4">
    <h1>Dashboard Admin</h1>
    <p class="text-muted">Bienvenue, <%= current_user.first_name || current_user.email %></p>
  </div>

  <!-- KPIs PRINCIPAUX (8 cartes) -->
  <div class="row g-3 mb-4">
    <!-- Utilisateurs -->
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Utilisateurs</h5>
          <h3 class="mb-0"><%= @stats[:total_users] %></h3>
        </div>
      </div>
    </div>

    <!-- Produits -->
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Produits</h5>
          <h3 class="mb-0"><%= @stats[:total_products] %></h3>
          <small class="text-muted"><%= @stats[:active_products] %> actifs</small>
        </div>
      </div>
    </div>

    <!-- Commandes -->
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Commandes</h5>
          <h3 class="mb-0"><%= @stats[:total_orders] %></h3>
          <small class="text-muted"><%= @stats[:pending_orders] %> en attente</small>
        </div>
      </div>
    </div>

    <!-- CA Total -->
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">CA Total</h5>
          <h3 class="mb-0"><%= number_to_currency(@stats[:total_revenue], unit: '€') %></h3>
          <small class="text-muted">Commandes payées/expédiées</small>
        </div>
      </div>
    </div>

    <!-- Stock Faible -->
    <div class="col-md-6 col-lg-3">
      <div class="card border-warning">
        <div class="card-body">
          <h5 class="card-title text-warning">⚠️ Stock Faible</h5>
          <h3 class="mb-0 text-warning"><%= @low_stock_count %></h3>
          <small class="text-muted">&lt; 10 unités</small>
        </div>
      </div>
    </div>

    <!-- Rupture Stock -->
    <div class="col-md-6 col-lg-3">
      <div class="card border-danger">
        <div class="card-body">
          <h5 class="card-title text-danger">🔴 Rupture</h5>
          <h3 class="mb-0 text-danger"><%= @out_of_stock_count %></h3>
          <small class="text-muted">0 unité disponible</small>
        </div>
      </div>
    </div>

    <!-- Initiations à venir -->
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Initiations</h5>
          <h3 class="mb-0"><%= @upcoming_initiations.count %></h3>
          <small class="text-muted">À venir</small>
        </div>
      </div>
    </div>

    <!-- Commandes Payées -->
    <div class="col-md-6 col-lg-3">
      <div class="card border-success">
        <div class="card-body">
          <h5 class="card-title text-success">✅ Payées</h5>
          <h3 class="mb-0 text-success"><%= @stats[:paid_orders] %></h3>
          <small class="text-muted">En préparation</small>
        </div>
      </div>
    </div>
  </div>

  <!-- GRAPHIQUE VENTES (7 derniers jours) -->
  <div class="row mb-4">
    <div class="col-12">
      <div class="card">
        <div class="card-header">
          <h5 class="mb-0">Ventes (7 derniers jours)</h5>
        </div>
        <div class="card-body">
          <!-- Graphique simple avec données -->
          <div class="chart-container" style="height: 200px;">
            <% if @sales_by_day.any? %>
              <div class="d-flex align-items-end" style="height: 100%;">
                <% @sales_by_day.each do |date, amount| %>
                  <div class="flex-fill d-flex flex-column align-items-center me-1">
                    <div class="bg-primary rounded-top" style="width: 100%; height: <%= (amount / @sales_by_day.values.max * 100) %>%;"></div>
                    <small class="text-muted mt-1"><%= date.strftime('%d/%m') %></small>
                    <small class="text-muted"><%= number_to_currency(amount, unit: '€', format: '%n') %></small>
                  </div>
                <% end %>
              </div>
            <% else %>
              <p class="text-muted text-center py-4">Aucune vente sur les 7 derniers jours</p>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- DEUX COLONNES : Commandes Récentes + Initiations à Venir -->
  <div class="row g-4">
    <!-- Commandes Récentes -->
    <div class="col-lg-8">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h5 class="mb-0">Commandes Récentes</h5>
          <%= link_to 'Voir toutes', admin_panel_orders_path, class: 'btn btn-sm btn-outline-primary' %>
        </div>
        <div class="card-body">
          <% if @recent_orders.any? %>
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="table-light">
                  <tr>
                    <th>ID</th>
                    <th>Client</th>
                    <th>Total</th>
                    <th>Statut</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <% @recent_orders.each do |order| %>
                    <tr>
                      <td>#<%= order.id %></td>
                      <td><%= order.user.email %></td>
                      <td><%= number_to_currency(order.total_cents / 100.0, unit: '€') %></td>
                      <td>
                        <span class="badge bg-<%= case order.status
                          when 'paid' then 'success'
                          when 'pending' then 'warning'
                          when 'shipped' then 'info'
                          when 'cancelled' then 'danger'
                          else 'secondary'
                        end %>">
                          <%= order.status %>
                        </span>
                      </td>
                      <td><%= order.created_at.strftime('%d/%m/%Y %H:%M') %></td>
                      <td>
                        <%= link_to 'Voir', admin_panel_order_path(order), class: 'btn btn-sm btn-outline-primary' %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <p class="text-muted text-center py-4">Aucune commande récente</p>
          <% end %>
        </div>
      </div>
    </div>

    <!-- Initiations à Venir -->
    <div class="col-lg-4">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h5 class="mb-0">Initiations à Venir</h5>
          <%= link_to 'Voir toutes', admin_panel_initiations_path, class: 'btn btn-sm btn-outline-primary' %>
        </div>
        <div class="card-body">
          <% if @upcoming_initiations.any? %>
            <div class="list-group list-group-flush">
              <% @upcoming_initiations.each do |initiation| %>
                <div class="list-group-item">
                  <h6 class="mb-1"><%= initiation.title %></h6>
                  <small class="text-muted">
                    <%= l(initiation.start_at, format: :short) %>
                  </small>
                  <div class="mt-2">
                    <span class="badge bg-info">
                      <%= initiation.participants_count %> / <%= initiation.max_participants %>
                    </span>
                    <% if initiation.volunteers_count > 0 %>
                      <span class="badge bg-success">
                        <%= initiation.volunteers_count %> bénévoles
                      </span>
                    <% end %>
                  </div>
                  <%= link_to 'Voir', admin_panel_initiation_path(initiation), class: 'btn btn-sm btn-outline-primary mt-2' %>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-muted text-center py-4">Aucune initiation à venir</p>
          <% end %>
        </div>
      </div>
    </div>
  </div>

  <!-- ACTIONS RAPIDES -->
  <div class="row mt-4">
    <div class="col-12">
      <div class="card">
        <div class="card-header">
          <h5 class="mb-0">Actions Rapides</h5>
        </div>
        <div class="card-body">
          <div class="btn-group" role="group">
            <%= link_to '+ Produit', new_admin_panel_product_path, class: 'btn btn-primary' %>
            <%= link_to 'Inventaire', admin_panel_inventory_path, class: 'btn btn-outline-primary' %>
            <%= link_to 'Commandes', admin_panel_orders_path, class: 'btn btn-outline-primary' %>
            <%= link_to 'Initiations', admin_panel_initiations_path, class: 'btn btn-outline-primary' %>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

## 🔐 Policy

**Fichier** : `app/policies/admin_panel/dashboard_policy.rb`

**Status** : ✅ Existe déjà (`app/policies/admin/dashboard_policy.rb`)

**À vérifier** : Namespace correct (`AdminPanel::DashboardPolicy`)

---

## 🛣️ Routes

**Fichier** : `config/routes.rb`

**Status** : ✅ Existe déjà

```ruby
namespace :admin_panel, path: 'admin-panel' do
  root 'dashboard#index'  # ✅ Existe
  get 'dashboard', to: 'dashboard#index'  # ✅ Existe
end
```

---

## ✅ Checklist

### **Phase 0-1 (Semaine 1)** ✅ COMPLÉTÉ
- [x] Améliorer DashboardController (KPIs avancés) ✅
- [x] Créer service AdminDashboardService ✅
- [x] Améliorer vue Dashboard (widgets, graphiques) ✅
- [x] Intégrer avec Inventories ✅
- [x] Intégrer avec Orders ✅
- [x] Intégrer avec Initiations ✅
- [x] Ajouter graphique ventes ✅
- [x] Ajouter actions rapides ✅

---

## 🔗 Dépendances

- **Inventories** : Pour afficher stock faible (nécessite [`01-boutique/inventaire.md`](../01-boutique/inventaire.md))
- **Orders** : Pour afficher CA (nécessite [`02-commandes/gestion-commandes.md`](../02-commandes/gestion-commandes.md))
- **Initiations** : Pour afficher initiations à venir (nécessite [`03-initiations/gestion-initiations.md`](../03-initiations/gestion-initiations.md))

---

## 📊 Widgets Implémentés ✅

1. **KPIs Principaux** (8 cartes) ✅
   - Utilisateurs ✅
   - Produits (total + actifs) ✅
   - Commandes (total + en attente) ✅
   - CA Total ✅
   - Stock Faible ✅
   - Rupture Stock ✅
   - Initiations à venir ✅
   - Commandes Payées ✅

2. **Graphique Ventes** (7 derniers jours) ✅
   - Barres simples avec données ✅
   - Remplissage automatique des jours manquants ✅

3. **Commandes Récentes** (tableau) ✅
   - 10 dernières commandes ✅
   - Lien vers détails ✅
   - Badges colorés selon statut ✅

4. **Initiations à Venir** (liste) ✅
   - 5 prochaines initiations ✅
   - Participants/Bénévoles ✅
   - Lien vers détails ✅

5. **Actions Rapides** (boutons) ✅
   - + Produit ✅
   - Inventaire ✅
   - Commandes ✅
   - Initiations ✅

6. **Mode Maintenance** (Admin uniquement) ✅
   - Affichage statut actuel ✅
   - Toggle avec confirmation ✅
   - Restrictions admin (level >= 60) ✅

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
