import { Controller } from "@hotwired/stimulus"

// GRID éditeur pour les variantes de produits
// Permet l'édition inline et la sélection multiple
export default class extends Controller {
  static values = {
    productId: Number
  }

  static targets = ["selectAll", "checkbox", "row", "priceInput"]

  connect() {
    this.updateBulkEditButton()
  }

  // Mettre à jour le bouton "Édition en masse" selon les cases cochées
  updateBulkEditButton() {
    const checkedBoxes = this.checkboxTargets.filter(cb => cb.checked)
    const bulkEditBtn = document.getElementById('bulk-edit-btn')
    
    if (bulkEditBtn) {
      if (checkedBoxes.length > 0) {
        bulkEditBtn.disabled = false
        const variantIds = checkedBoxes.map(cb => cb.value).join(',')
        bulkEditBtn.href = bulkEditBtn.href.split('?')[0] + `?variant_ids[]=${variantIds}`
      } else {
        bulkEditBtn.disabled = true
      }
    }
  }

  // Cocher/décocher toutes les cases
  selectAllChanged() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateBulkEditButton()
  }

  // Sauvegarder le prix modifié (édition inline)
  async savePrice(event) {
    const input = event.target
    const variantId = input.dataset.variantId
    const productId = this.productIdValue
    const priceValue = parseFloat(input.value)
    
    if (isNaN(priceValue) || priceValue < 0) {
      input.classList.add('is-invalid')
      return
    }
    
    const priceCents = Math.round(priceValue * 100)
    const originalValue = input.dataset.originalValue || input.value
    
    // Marquer comme en cours de sauvegarde
    input.disabled = true
    input.classList.remove('is-invalid', 'is-modified')
    input.classList.add('is-saving')
    
    try {
      const response = await fetch(`/admin-panel/products/${productId}/product_variants/${variantId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          product_variant: {
            price_cents: priceCents
          }
        })
      })
      
      if (response.ok) {
        const data = await response.json()
        input.classList.remove('is-saving')
    input.classList.add('is-modified')
        input.dataset.originalValue = input.value
        
        // Retirer la classe après 2 secondes
        setTimeout(() => {
          input.classList.remove('is-modified')
        }, 2000)
      } else {
        const error = await response.json()
        throw new Error(error.message || 'Erreur lors de la sauvegarde')
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde du prix:', error)
      input.classList.remove('is-saving')
      input.classList.add('is-invalid')
      input.value = originalValue
      alert('Erreur lors de la sauvegarde du prix: ' + error.message)
    } finally {
      input.disabled = false
    }
  }
}

