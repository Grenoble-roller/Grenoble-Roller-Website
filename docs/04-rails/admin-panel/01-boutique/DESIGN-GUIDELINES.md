# 🎨 GUIDE DE DESIGN - Panel Admin Boutique

**Version** : 2.0 | **Date** : 2025-12-24 | **Références** : Shopify, WooCommerce, Magento

---

## 📋 Table des Matières

1. [Principes Fondamentaux](#principes-fondamentaux)
2. [Architecture des Formulaires](#architecture-des-formulaires)
3. [Design System](#design-system)
4. [Formulaires Produits](#formulaires-produits)
5. [Gestion Variantes](#gestion-variantes)
6. [Images & Médias](#images--médias)
7. [Validation & Feedback](#validation--feedback)
8. [Responsive Design](#responsive-design)
9. [Accessibilité (WCAG 2.1)](#accessibilité-wcag-21)
10. [Performance](#performance)

---

## 🎯 Principes Fondamentaux

### 1. **Simplicité & Clarté**
- **Un objectif par écran** : Chaque page a un objectif clair et unique
- **Hiérarchie visuelle** : Les éléments importants sont mis en avant
- **Espace blanc** : Utilisation généreuse pour améliorer la lisibilité
- **Progressive Disclosure** : Afficher les informations par ordre d'importance

### 2. **Efficacité**
- **Actions rapides** : Les actions fréquentes sont accessibles en 1-2 clics
- **Auto-save** : Sauvegarde automatique des brouillons toutes les 30 secondes
- **Raccourcis clavier** : Support des raccourcis pour les actions courantes
- **Bulk actions** : Possibilité de modifier plusieurs éléments à la fois

### 3. **Feedback Immédiat**
- **Validation en temps réel** : Vérification des champs au fur et à mesure
- **Indicateurs de statut** : Sauvegarde, erreurs, succès visibles immédiatement
- **Messages contextuels** : Aide et conseils au bon moment
- **Prévisualisation** : Aperçu du produit avant publication

### 4. **Cohérence**
- **Design System** : Utilisation cohérente des composants
- **Terminologie** : Vocabulaire uniforme dans toute l'interface
- **Navigation** : Structure de navigation prévisible
- **Interactions** : Comportements similaires pour actions similaires

---

## 🏗️ Architecture des Formulaires

### **Structure en Sections/Tabs (Style Shopify)**

Les formulaires de produits doivent être organisés en sections claires :

```
┌─────────────────────────────────────────────────────────┐
│  [Produit] [Prix] [Inventaire] [Variantes] [SEO] [...]  │  ← Tabs horizontaux
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Section active : [Produit]                              │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Informations de base                             │    │
│  │ - Nom *                                          │    │
│  │ - Description                                    │    │
│  │ - Catégorie *                                    │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Images                                           │    │
│  │ [Upload zone avec drag & drop]                  │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Options & Variantes                             │    │
│  │ [Sélection types d'options]                    │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  [Sauvegarder] [Publier] [Aperçu]                        │
└─────────────────────────────────────────────────────────┘
```

### **Sections Obligatoires**

1. **Informations de base** (toujours visible)
   - Nom, Description, Catégorie, Slug

2. **Prix & Inventaire**
   - Prix de base, Devise, Stock initial

3. **Images**
   - Upload multiple avec drag & drop
   - Preview avec réorganisation

4. **Variantes** (si applicable)
   - Sélection options
   - Génération automatique
   - GRID éditeur

5. **SEO** (optionnel mais recommandé)
   - Meta title, Meta description
   - URL personnalisée

6. **Publication**
   - Statut (Brouillon/Actif)
   - Date de publication
   - Visibilité

---

## 🎨 Design System

### **Palette de Couleurs**

```scss
// Couleurs principales (Liquid Glass)
--liquid-primary: #007bff;
--liquid-success: #28a745;
--liquid-warning: #ffc107;
--liquid-danger: #dc3545;
--liquid-info: #17a2b8;

// Couleurs neutres
--bs-gray-50: #f8f9fa;
--bs-gray-100: #e9ecef;
--bs-gray-200: #dee2e6;
--bs-gray-300: #ced4da;
--bs-gray-400: #adb5bd;
--bs-gray-500: #6c757d;
--bs-gray-600: #495057;
--bs-gray-700: #343a40;
--bs-gray-800: #212529;
--bs-gray-900: #000;

// États
--state-success-bg: rgba(40, 167, 69, 0.1);
--state-warning-bg: rgba(255, 193, 7, 0.1);
--state-danger-bg: rgba(220, 53, 69, 0.1);
--state-info-bg: rgba(23, 162, 184, 0.1);
```

### **Typographie**

```scss
// Hiérarchie
--font-size-h1: 2rem;      // 32px
--font-size-h2: 1.75rem;    // 28px
--font-size-h3: 1.5rem;     // 24px
--font-size-h4: 1.25rem;    // 20px
--font-size-h5: 1.125rem;   // 18px
--font-size-h6: 1rem;       // 16px
--font-size-body: 0.875rem;  // 14px
--font-size-small: 0.75rem;  // 12px

// Poids
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
```

### **Espacements**

```scss
// Spacing scale (8px base)
--spacing-xs: 0.25rem;   // 4px
--spacing-sm: 0.5rem;    // 8px
--spacing-md: 1rem;      // 16px
--spacing-lg: 1.5rem;    // 24px
--spacing-xl: 2rem;      // 32px
--spacing-2xl: 3rem;     // 48px
--spacing-3xl: 4rem;     // 64px
```

### **Composants**

#### **Cards (Liquid Glass)**

```scss
.card-liquid {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: var(--bs-border-radius-lg);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  padding: var(--spacing-lg);
}

.card-liquid-primary {
  background: rgba(var(--bs-primary-rgb), 0.1);
  border-color: rgba(var(--bs-primary-rgb), 0.2);
}
```

#### **Form Controls**

```scss
.form-control-liquid {
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: var(--bs-border-radius);
  padding: 0.5rem 0.75rem;
  transition: all 0.2s ease;

  &:focus {
    background: rgba(255, 255, 255, 0.95);
    border-color: var(--liquid-primary);
    box-shadow: 0 0 0 0.2rem rgba(var(--bs-primary-rgb), 0.25);
  }
}
```

#### **Buttons**

```scss
.btn-liquid-primary {
  background: linear-gradient(135deg, var(--liquid-primary), #0056b3);
  border: none;
  color: white;
  padding: 0.5rem 1.5rem;
  border-radius: var(--bs-border-radius);
  font-weight: 500;
  transition: all 0.2s ease;

  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(var(--bs-primary-rgb), 0.3);
  }
}
```

---

## 📝 Formulaires Produits

### **Structure du Formulaire**

#### **1. Header avec Actions**

```erb
<div class="product-form-header">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h1 class="h3 mb-1">
        <%= @product.persisted? ? "Modifier le produit" : "Nouveau produit" %>
      </h1>
      <p class="text-muted mb-0">
        <%= @product.persisted? ? "Dernière modification : #{time_ago_in_words(@product.updated_at)}" : "Remplissez les informations ci-dessous" %>
      </p>
    </div>
    <div class="btn-group">
      <%= link_to "Aperçu", preview_path, class: "btn btn-outline-secondary", target: "_blank" %>
      <%= f.submit "Enregistrer", class: "btn btn-liquid-primary", name: "save_draft" %>
      <%= f.submit "Publier", class: "btn btn-success", name: "publish" %>
    </div>
  </div>
</div>
```

#### **2. Tabs Navigation**

```erb
<ul class="nav nav-tabs mb-4" role="tablist">
  <li class="nav-item" role="presentation">
    <button class="nav-link active" id="product-tab" data-bs-toggle="tab" 
            data-bs-target="#product" type="button" role="tab">
      <i class="bi bi-box me-2"></i>Produit
    </button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="pricing-tab" data-bs-toggle="tab" 
            data-bs-target="#pricing" type="button" role="tab">
      <i class="bi bi-currency-euro me-2"></i>Prix
    </button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="inventory-tab" data-bs-toggle="tab" 
            data-bs-target="#inventory" type="button" role="tab">
      <i class="bi bi-box-seam me-2"></i>Inventaire
    </button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="variants-tab" data-bs-toggle="tab" 
            data-bs-target="#variants" type="button" role="tab">
      <i class="bi bi-layers me-2"></i>Variantes
    </button>
  </li>
  <li class="nav-item" role="presentation">
    <button class="nav-link" id="seo-tab" data-bs-toggle="tab" 
            data-bs-target="#seo" type="button" role="tab">
      <i class="bi bi-search me-2"></i>SEO
    </button>
  </li>
</ul>
```

#### **3. Tab Content avec Sections**

```erb
<div class="tab-content">
  <!-- Tab 1: Produit -->
  <div class="tab-pane fade show active" id="product" role="tabpanel">
    <!-- Section: Informations de base -->
    <div class="card card-liquid mb-4">
      <div class="card-header card-liquid-primary">
        <h5 class="mb-0">
          <i class="bi bi-info-circle me-2"></i>Informations de base
        </h5>
      </div>
      <div class="card-body">
        <!-- Champs formulaire -->
      </div>
    </div>

    <!-- Section: Images -->
    <div class="card card-liquid mb-4">
      <div class="card-header card-liquid-primary">
        <h5 class="mb-0">
          <i class="bi bi-images me-2"></i>Images du produit
        </h5>
      </div>
      <div class="card-body">
        <!-- Upload zone drag & drop -->
      </div>
    </div>
  </div>

  <!-- Autres tabs... -->
</div>
```

### **Champs de Formulaire**

#### **Nom du Produit**

```erb
<div class="mb-4">
  <%= f.label :name, "Nom du produit", class: "form-label fw-semibold" do %>
    Nom du produit <span class="text-danger">*</span>
  <% end %>
  <%= f.text_field :name, 
      class: "form-control form-control-liquid",
      placeholder: "Ex: Casque LED rechargeable",
      maxlength: 140,
      required: true,
      data: { 
        controller: "auto-save",
        auto_save_field_value: "name"
      } %>
  <div class="form-text">
    <i class="bi bi-info-circle me-1"></i>
    Maximum 140 caractères. 
    <span class="char-count" data-target="name">0/140</span>
  </div>
  <div class="invalid-feedback"></div>
</div>
```

#### **Description (Rich Text Editor)**

```erb
<div class="mb-4">
  <%= f.label :description, "Description", class: "form-label fw-semibold" %>
  <%= f.text_area :description,
      class: "form-control form-control-liquid",
      rows: 6,
      placeholder: "Décrivez votre produit en détail...",
      data: { 
        controller: "rich-text-editor",
        rich_text_editor_toolbar_value: "basic"
      } %>
  <div class="form-text">
    <i class="bi bi-info-circle me-1"></i>
    Utilisez un langage clair et descriptif pour aider les clients à comprendre votre produit.
  </div>
</div>
```

#### **Catégorie avec Recherche**

```erb
<div class="mb-4">
  <%= f.label :category_id, "Catégorie", class: "form-label fw-semibold" do %>
    Catégorie <span class="text-danger">*</span>
  <% end %>
  <%= f.select :category_id,
      options_from_collection_for_select(@categories, :id, :name, @product.category_id),
      { include_blank: "Sélectionner une catégorie" },
      { 
        class: "form-select form-control-liquid",
        required: true,
        data: { 
          controller: "select-search",
          select_search_placeholder_value: "Rechercher une catégorie..."
        }
      } %>
  <div class="form-text">
    <i class="bi bi-info-circle me-1"></i>
    La catégorie aide les clients à trouver votre produit.
  </div>
</div>
```

---

## 🎯 Gestion Variantes

### **GRID Éditeur (Style Shopify)**

#### **Structure du GRID**

```erb
<div class="variants-grid-container">
  <!-- Header avec actions bulk -->
  <div class="variants-grid-header d-flex justify-content-between align-items-center mb-3">
    <div>
      <h5 class="mb-0">Variantes (<span id="variants-count"><%= @variants.count %></span>)</h5>
      <p class="text-muted small mb-0">Gérez les variantes de votre produit</p>
    </div>
    <div class="btn-group">
      <button type="button" class="btn btn-sm btn-outline-secondary" 
              id="bulk-edit-btn" disabled>
        <i class="bi bi-pencil me-1"></i>Édition en masse
      </button>
      <%= link_to new_admin_panel_product_product_variant_path(@product),
          class: "btn btn-sm btn-liquid-primary" do %>
        <i class="bi bi-plus-lg me-1"></i>Ajouter une variante
      <% end %>
    </div>
  </div>

  <!-- Table GRID -->
  <div class="card card-liquid">
    <div class="table-responsive">
      <table class="table table-hover mb-0 variants-grid-table"
             data-controller="variants-grid">
        <thead>
          <tr>
            <th style="width: 40px;">
              <input type="checkbox" 
                     id="select-all-variants"
                     class="form-check-input"
                     data-action="change->variants-grid#toggleAll">
            </th>
            <th>Image</th>
            <th>SKU</th>
            <th>Options</th>
            <th>Prix</th>
            <th>Stock</th>
            <th>Statut</th>
            <th style="width: 120px;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <% @variants.each do |variant| %>
            <%= render 'grid_row', variant: variant %>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

#### **Row avec Édition Inline**

```erb
<tr class="variant-row" 
    data-variant-id="<%= variant.id %>"
    data-variants-grid-target="row">
  
  <!-- Checkbox -->
  <td>
    <input type="checkbox" 
           class="form-check-input variant-checkbox"
           value="<%= variant.id %>"
           data-action="change->variants-grid#updateBulkButton">
  </td>

  <!-- Image -->
  <td>
    <div class="variant-image-thumbnail">
      <% if variant.images.attached? %>
        <%= image_tag variant.images.first, 
            class: "img-thumbnail",
            style: "width: 50px; height: 50px; object-fit: cover;" %>
      <% else %>
        <div class="bg-light d-flex align-items-center justify-content-center"
             style="width: 50px; height: 50px; border-radius: 4px;">
          <i class="bi bi-image text-muted"></i>
        </div>
      <% end %>
    </div>
  </td>

  <!-- SKU -->
  <td>
    <code class="variant-sku"><%= variant.sku %></code>
  </td>

  <!-- Options -->
  <td>
    <div class="variant-options">
      <% variant.option_values.each do |ov| %>
        <span class="badge bg-light text-dark me-1">
          <%= "#{ov.option_type.name}: #{ov.value}" %>
        </span>
      <% end %>
    </div>
  </td>

  <!-- Prix (Édition inline) -->
  <td>
    <div class="input-group input-group-sm" style="width: 120px;">
      <input type="number"
             class="form-control form-control-sm variant-price-input"
             value="<%= variant.price_cents / 100.0 %>"
             step="0.01"
             min="0"
             data-variant-id="<%= variant.id %>"
             data-field="price_cents"
             data-action="blur->variants-grid#saveField change->variants-grid#markDirty">
      <span class="input-group-text">€</span>
    </div>
    <div class="save-indicator" style="display: none;">
      <i class="bi bi-check-circle text-success"></i>
    </div>
  </td>

  <!-- Stock (Édition inline) -->
  <td>
    <div class="d-flex align-items-center gap-2">
      <div class="input-group input-group-sm" style="width: 100px;">
        <input type="number"
               class="form-control form-control-sm variant-stock-input"
               value="<%= variant.inventory&.available_qty || 0 %>"
               step="1"
               min="0"
               data-variant-id="<%= variant.id %>"
               data-field="stock_qty"
               data-action="blur->variants-grid#saveField change->variants-grid#markDirty">
      </div>
      <span class="badge bg-<%= variant.inventory&.available_qty&.> 0 ? 'success' : 'danger' %>">
        <%= variant.inventory&.available_qty || 0 %> dispo
      </span>
    </div>
  </td>

  <!-- Statut (Toggle) -->
  <td>
    <div class="form-check form-switch">
      <input class="form-check-input variant-status-toggle"
             type="checkbox"
             <%= 'checked' if variant.is_active %>
             data-variant-id="<%= variant.id %>"
             data-action="change->variants-grid#toggleStatus">
      <label class="form-check-label">
        <span class="badge bg-<%= variant.is_active ? 'success' : 'secondary' %>">
          <%= variant.is_active ? 'Actif' : 'Inactif' %>
        </span>
      </label>
    </div>
  </td>

  <!-- Actions -->
  <td>
    <div class="btn-group btn-group-sm">
      <%= link_to edit_admin_panel_product_product_variant_path(@product, variant),
          class: "btn btn-outline-warning",
          title: "Modifier" do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      <%= link_to admin_panel_product_product_variant_path(@product, variant),
          method: :delete,
          class: "btn btn-outline-danger",
          title: "Supprimer",
          data: { 
            confirm: "Êtes-vous sûr de vouloir supprimer cette variante ?",
            turbo_method: :delete
          } do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
```

---

## 🖼️ Images & Médias

### **Upload Zone avec Drag & Drop**

```erb
<div class="image-upload-zone" 
     data-controller="image-upload"
     data-image-upload-max-size-value="5242880"
     data-image-upload-accepted-types-value="image/jpeg,image/png,image/webp">
  
  <!-- Zone de drop -->
  <div class="drop-zone border-2 border-dashed rounded p-5 text-center"
       data-image-upload-target="dropZone"
       data-action="dragover->image-upload#handleDragOver 
                    drop->image-upload#handleDrop 
                    dragleave->image-upload#handleDragLeave">
    <i class="bi bi-cloud-upload display-4 text-muted mb-3"></i>
    <p class="mb-2">
      <strong>Glissez-déposez vos images ici</strong>
    </p>
    <p class="text-muted small mb-3">
      ou cliquez pour sélectionner
    </p>
    <input type="file" 
           multiple
           accept="image/jpeg,image/png,image/webp"
           class="d-none"
           data-image-upload-target="fileInput"
           data-action="change->image-upload#handleFiles">
    <button type="button" 
            class="btn btn-outline-primary"
            data-action="click->image-upload#triggerFileInput">
      <i class="bi bi-upload me-2"></i>Sélectionner des fichiers
    </button>
    <p class="text-muted small mt-3 mb-0">
      Formats acceptés : JPG, PNG, WebP (max 5MB)
    </p>
  </div>

  <!-- Preview des images uploadées -->
  <div class="image-preview-grid mt-4" data-image-upload-target="previewGrid">
    <!-- Images seront ajoutées ici dynamiquement -->
  </div>
</div>
```

### **Preview d'Image avec Actions**

```erb
<div class="image-preview-item" data-image-id="<%= image.id %>">
  <div class="position-relative">
    <%= image_tag image, 
        class: "img-thumbnail w-100",
        style: "height: 200px; object-fit: cover;" %>
    
    <!-- Overlay avec actions -->
    <div class="image-overlay position-absolute top-0 start-0 w-100 h-100 
                d-flex align-items-center justify-content-center 
                bg-dark bg-opacity-50 opacity-0"
         style="transition: opacity 0.2s;">
      <div class="btn-group">
        <button type="button" 
                class="btn btn-sm btn-light"
                title="Définir comme image principale"
                data-action="click->image-upload#setAsPrimary">
          <i class="bi bi-star"></i>
        </button>
        <button type="button" 
                class="btn btn-sm btn-light"
                title="Réorganiser"
                data-action="mousedown->image-upload#startDrag">
          <i class="bi bi-arrows-move"></i>
        </button>
        <button type="button" 
                class="btn btn-sm btn-danger"
                title="Supprimer"
                data-action="click->image-upload#removeImage">
          <i class="bi bi-trash"></i>
        </button>
      </div>
    </div>

    <!-- Badge image principale -->
    <% if image.id == @product.primary_image_id %>
      <span class="position-absolute top-0 start-0 badge bg-primary m-2">
        <i class="bi bi-star-fill me-1"></i>Principale
      </span>
    <% end %>
  </div>
</div>
```

---

## ✅ Validation & Feedback

### **Validation en Temps Réel**

```javascript
// Stimulus Controller: form-validation
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "feedback", "submit"]

  connect() {
    this.validateAll()
  }

  validateField(event) {
    const field = event.target
    const fieldName = field.name
    const value = field.value

    // Validation spécifique par champ
    let isValid = true
    let errorMessage = ""

    switch(fieldName) {
      case "product[name]":
        if (value.length < 3) {
          isValid = false
          errorMessage = "Le nom doit contenir au moins 3 caractères"
        } else if (value.length > 140) {
          isValid = false
          errorMessage = "Le nom ne peut pas dépasser 140 caractères"
        }
        break

      case "product[price_cents]":
        if (parseFloat(value) <= 0) {
          isValid = false
          errorMessage = "Le prix doit être supérieur à 0"
        }
        break

      // ... autres validations
    }

    this.updateFieldState(field, isValid, errorMessage)
    this.updateSubmitButton()
  }

  updateFieldState(field, isValid, errorMessage) {
    if (isValid) {
      field.classList.remove("is-invalid")
      field.classList.add("is-valid")
      const feedback = field.parentElement.querySelector(".invalid-feedback")
      if (feedback) feedback.textContent = ""
    } else {
      field.classList.remove("is-valid")
      field.classList.add("is-invalid")
      const feedback = field.parentElement.querySelector(".invalid-feedback")
      if (feedback) feedback.textContent = errorMessage
    }
  }

  updateSubmitButton() {
    const allValid = this.fieldTargets.every(field => 
      field.classList.contains("is-valid") || 
      !field.hasAttribute("required")
    )

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !allValid
    }
  }

  validateAll() {
    this.fieldTargets.forEach(field => {
      if (field.hasAttribute("required")) {
        this.validateField({ target: field })
      }
    })
  }
}
```

### **Indicateurs de Sauvegarde**

```erb
<!-- Barre de statut en bas -->
<div class="form-status-bar position-fixed bottom-0 start-0 w-100 bg-white border-top p-3"
     data-controller="auto-save-status"
     style="z-index: 1000; display: none;">
  <div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center">
      <div>
        <i class="bi bi-clock-history me-2"></i>
        <span data-auto-save-status-target="message">Enregistrement automatique...</span>
      </div>
      <div>
        <span class="badge bg-success" data-auto-save-status-target="lastSave" style="display: none;">
          Dernière sauvegarde : <span data-auto-save-status-target="time"></span>
        </span>
      </div>
    </div>
  </div>
</div>
```

---

## 📱 Responsive Design

### **Breakpoints**

```scss
// Mobile First
$breakpoints: (
  xs: 0,
  sm: 576px,
  md: 768px,
  lg: 992px,
  xl: 1200px,
  xxl: 1400px
);
```

### **Adaptations Mobile**

#### **Tabs → Accordion sur Mobile**

```erb
<!-- Desktop: Tabs -->
<ul class="nav nav-tabs d-none d-md-flex" role="tablist">
  <!-- Tabs -->
</ul>

<!-- Mobile: Accordion -->
<div class="accordion d-md-none mb-4" id="productFormAccordion">
  <div class="accordion-item">
    <h2 class="accordion-header">
      <button class="accordion-button" type="button" data-bs-toggle="collapse" 
              data-bs-target="#productCollapse">
        <i class="bi bi-box me-2"></i>Produit
      </button>
    </h2>
    <div id="productCollapse" class="accordion-collapse collapse show">
      <div class="accordion-body">
        <!-- Contenu -->
      </div>
    </div>
  </div>
  <!-- Autres sections -->
</div>
```

#### **GRID → Cards sur Mobile**

```scss
@media (max-width: 767px) {
  .variants-grid-table {
    display: none; // Masquer le tableau
  }

  .variants-grid-cards {
    display: block; // Afficher les cards
  }

  .variant-card {
    background: white;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 1rem;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

    .variant-card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }

    .variant-card-body {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.75rem;
    }
  }
}
```

---

## ♿ Accessibilité (WCAG 2.1)

### **Contraste des Couleurs**

- **Texte normal** : Ratio minimum 4.5:1
- **Texte large** : Ratio minimum 3:1
- **Éléments interactifs** : Ratio minimum 3:1

### **Navigation Clavier**

- **Tab** : Navigation entre les éléments interactifs
- **Enter/Space** : Activer les boutons
- **Escape** : Fermer les modales
- **Flèches** : Navigation dans les listes

### **ARIA Labels**

```erb
<button type="button" 
        class="btn btn-primary"
        aria-label="Publier le produit"
        aria-describedby="publish-help">
  <i class="bi bi-check-circle me-2" aria-hidden="true"></i>
  Publier
</button>
<span id="publish-help" class="visually-hidden">
  Publie le produit et le rend visible sur le site
</span>
```

### **Focus Visible**

```scss
*:focus-visible {
  outline: 2px solid var(--liquid-primary);
  outline-offset: 2px;
  border-radius: 2px;
}
```

---

## ⚡ Performance

### **Lazy Loading des Images**

```erb
<%= image_tag image, 
    loading: "lazy",
    decoding: "async",
    class: "img-thumbnail" %>
```

### **Debounce sur les Champs**

```javascript
// Dans le controller Stimulus
saveField(event) {
  clearTimeout(this.saveTimeout)
  
  this.saveTimeout = setTimeout(() => {
    // Sauvegarder après 500ms d'inactivité
    this.performSave(event.target)
  }, 500)
}
```

### **Pagination des Variantes**

```ruby
# Controller
@pagy, @variants = pagy(@variants, items: 50) # Limiter à 50 par page
```

---

## 📚 Références

- **Shopify Admin** : https://help.shopify.com/en/manual/products
- **WooCommerce** : https://woocommerce.com/document/product-data/
- **WCAG 2.1** : https://www.w3.org/WAI/WCAG21/quickref/
- **Bootstrap 5** : https://getbootstrap.com/docs/5.3/

---

**Dernière mise à jour** : 2025-12-24  
**Version** : 2.0  
**Auteur** : FlowTech AI

