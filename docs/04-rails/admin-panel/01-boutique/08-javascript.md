# ⚡ JAVASCRIPT - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 4 | **Semaine** : 4  
**Version** : 2.0 | **Dernière mise à jour** : 2025-12-24

---

## 📋 Description

Controller Stimulus pour l'édition inline dans le GRID des variantes, validation en temps réel, auto-save, et autres interactions avancées.

**🎨 Design & UX** : Voir [DESIGN-GUIDELINES.md](./DESIGN-GUIDELINES.md) pour les spécifications complètes des interactions JavaScript (validation, debounce, feedback, etc.)

---

## ✅ Controller Stimulus : ProductVariantsGrid

**Fichier** : `app/javascript/controllers/admin_panel/product_variants_grid_controller.js`

**Code exact** :
```javascript
import { Controller } from "@hotwired/stimulus"
import { debounce } from "lodash-es"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "row", "priceInput"]
  static values = { productId: Number }
  
  connect() {
    this.setupCheckboxes()
    this.setupPriceEditing()
  }
  
  // ==========================================
  // GESTION CHECKBOXES (Sélection multiple)
  // ==========================================
  
  setupCheckboxes() {
    this.selectAllTarget?.addEventListener('change', (e) => {
      this.checkboxTargets.forEach(cb => {
        cb.checked = e.target.checked
      })
      this.updateBulkEditButton()
    })
    
    // Mettre à jour "select all" si toutes les checkboxes sont cochées
    this.checkboxTargets.forEach(cb => {
      cb.addEventListener('change', () => {
        this.updateSelectAll()
        this.updateBulkEditButton()
      })
    })
  }
  
  updateSelectAll() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    const someChecked = this.checkboxTargets.some(cb => cb.checked)
    
    if (this.selectAllTarget) {
      this.selectAllTarget.checked = allChecked
      this.selectAllTarget.indeterminate = someChecked && !allChecked
    }
  }
  
  updateBulkEditButton() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length
    const bulkEditBtn = document.getElementById('bulk-edit-btn')
    
    if (bulkEditBtn) {
      bulkEditBtn.disabled = checkedCount === 0
      
      if (checkedCount > 0) {
        const url = new URL(bulkEditBtn.href)
        const variantIds = this.checkboxTargets
          .filter(cb => cb.checked)
          .map(cb => cb.value)
        url.searchParams.set('variant_ids', variantIds.join(','))
        bulkEditBtn.href = url.toString()
      }
    }
  }
  
  // ==========================================
  // ÉDITION INLINE PRIX
  // ==========================================
  
  setupPriceEditing() {
    this.priceInputTargets.forEach(input => {
      input.dataset.original = input.value
      
      input.addEventListener('change', () => {
        this.savePrice(input)
      })
      
      input.addEventListener('blur', () => {
        // Restaurer valeur originale si annulé
        if (input.dataset.saving === 'true') {
          input.value = input.dataset.original
          input.dataset.saving = 'false'
        }
      })
    })
  }
  
  // Debounce pour éviter trop de requêtes
  savePrice = debounce((input) => {
    const variantId = input.dataset.variantId
    const field = input.dataset.field
    const newValue = parseFloat(input.value)
    const original = parseFloat(input.dataset.original)
    
    // Validation client
    if (isNaN(newValue) || newValue <= 0) {
      this.showError(input, 'Prix doit être > 0')
      input.value = original
      return
    }
    
    // Convertir en cents si nécessaire
    const valueInCents = field === 'price_cents' ? Math.round(newValue * 100) : newValue
    
    // Indicateur de chargement
    input.classList.add('saving')
    input.dataset.saving = 'true'
    input.disabled = true
    
    const row = input.closest('tr')
    const csrfToken = document.querySelector('[name="csrf-token"]')?.content
    
    fetch(`/admin-panel/products/${this.productIdValue}/product_variants/${variantId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        product_variant: {
          [field]: valueInCents
        }
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Erreur de sauvegarde')
      }
      return response.json()
    })
    .then(data => {
      // Succès
      input.dataset.original = newValue.toString()
      input.classList.remove('saving')
      input.classList.add('saved')
      input.disabled = false
      input.dataset.saving = 'false'
      
      // Retirer classe "saved" après 2 secondes
      setTimeout(() => {
        input.classList.remove('saved')
      }, 2000)
      
      // Feedback visuel sur la ligne
      if (row) {
        row.classList.add('table-success')
        setTimeout(() => {
          row.classList.remove('table-success')
        }, 2000)
      }
    })
    .catch(error => {
      // Erreur
      this.showError(input, error.message || 'Erreur de sauvegarde')
      input.value = original
      input.classList.remove('saving')
      input.disabled = false
      input.dataset.saving = 'false'
    })
  }, 500) // Debounce 500ms
  
  showError(input, message) {
    // Afficher message d'erreur temporaire
    const errorDiv = document.createElement('div')
    errorDiv.className = 'alert alert-danger alert-dismissible fade show position-fixed'
    errorDiv.style.cssText = 'top: 20px; right: 20px; z-index: 9999;'
    errorDiv.innerHTML = `
      <strong>Erreur :</strong> ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    document.body.appendChild(errorDiv)
    
    // Retirer après 5 secondes
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }
}
```

---

## ✅ Styles CSS (Optionnel)

**Fichier** : `app/assets/stylesheets/admin_panel/product_variants.scss`

**Code exact** :
```scss
// États de sauvegarde
.variant-row {
  input.saving {
    background-color: #fff3cd;
    border-color: #ffc107;
  }
  
  input.saved {
    background-color: #d1e7dd;
    border-color: #198754;
  }
}

// Animation de succès
.table-success {
  animation: flashSuccess 2s ease-in-out;
}

@keyframes flashSuccess {
  0%, 100% { background-color: transparent; }
  50% { background-color: rgba(25, 135, 84, 0.1); }
}
```

---

## ✅ Controller Stimulus : ProductForm (NOUVEAU - 2025-12-24)

**Fichier** : `app/javascript/controllers/product_form_controller.js`

**Fonctionnalités** :
- ✅ Validation en temps réel (nom, slug, catégorie, prix)
- ✅ Compteurs de caractères (nom, meta title, meta description)
- ✅ Auto-save avec debounce (2s) et sauvegarde périodique (30s)
- ✅ Génération automatique du slug depuis le nom
- ✅ Preview variants avant génération
- ✅ Barre de statut avec indicateurs visuels
- ✅ Toggle mode variantes (auto/manual)

---

## ✅ Controller Stimulus : ImageUpload (NOUVEAU - 2025-12-24)

**Fichier** : `app/javascript/controllers/image_upload_controller.js`

**Fonctionnalités** :
- ✅ Drag & drop pour upload images
- ✅ Preview des images avant upload
- ✅ Validation des fichiers (type, taille)
- ✅ Suppression d'images (actuelles et preview)
- ✅ Formatage de la taille des fichiers

---

## ✅ Checklist Globale

### **Phase 4 (Semaine 4)** ✅
- [x] Créer controller Stimulus `product_variants_grid_controller.js`
- [x] Créer controller Stimulus `product_form_controller.js`
- [x] Créer controller Stimulus `image_upload_controller.js`
- [x] Implémenter gestion checkboxes (select all)
- [x] Implémenter édition inline prix avec debounce (500ms)
- [x] Implémenter validation client en temps réel
- [x] Implémenter feedback visuel (saving, saved)
- [x] Implémenter auto-save avec indicateurs
- [x] Implémenter drag & drop pour images
- [x] Ajouter styles CSS (optionnel)
- [x] Tester édition inline
- [x] Tester sélection multiple

---

## 🔧 Améliorations Futures

- **Optimistic Locking** : Vérifier version avant sauvegarde
- **Édition inline stock** : Permettre édition stock directement
- **Drag & Drop images** : Réorganiser images variantes
- **Bulk actions** : Activer/désactiver plusieurs variantes

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
