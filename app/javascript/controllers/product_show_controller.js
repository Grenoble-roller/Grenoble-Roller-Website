import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sizeSelect",
    "colorSelect",
    "variantInput",
    "addButton",
    "stockHint",
    "stockValue",
    "qtyField",
    "priceDisplay",
    "unitPriceValue",
    "productImage",
    "modal"
  ]

  static values = {
    variants: Array,
    defaultImageUrl: String
  }

  connect() {
    // Sauvegarder le src initial de l'image (généré par image_tag)
    if (this.hasProductImageTarget && this.productImageTarget.src) {
      this.initialImageSrc = this.productImageTarget.src
    }
    
    // Écouter l'ouverture du modal pour mettre à jour l'image juste avant l'affichage
    const modalElement = document.getElementById('productImageModalShow')
    if (modalElement) {
      modalElement.addEventListener('show.bs.modal', () => {
        this.updateModalImage()
      })
    }
    
    // Ne mettre à jour que si une option est déjà sélectionnée
    // Sinon, garder l'image initiale et les valeurs par défaut
    const hasSelection = (this.hasSizeSelectTarget && this.sizeSelectTarget.value) || 
                        (this.hasColorSelectTarget && this.colorSelectTarget.value)
    if (hasSelection) {
      this.updateVariant()
    }
  }
  
  updateModalImage() {
    // Mettre à jour l'image du modal avec l'image actuelle du produit
    const modalImage = document.getElementById('productModalImage')
    if (modalImage && this.hasProductImageTarget && this.productImageTarget.src) {
      modalImage.src = this.productImageTarget.src
    }
  }

  sizeChanged() {
    this.updateVariant()
  }

  colorChanged() {
    this.updateVariant()
  }

  quantityChanged() {
    this.updateVariant()
  }

  incrementQty() {
    if (!this.hasQtyFieldTarget) return
    const max = parseInt(this.qtyFieldTarget.max || '0', 10)
    const current = parseInt(this.qtyFieldTarget.value || '1', 10)
    if (max > 0 && current < max) {
      this.qtyFieldTarget.value = current + 1
      this.updateVariant()
    }
  }

  decrementQty() {
    if (!this.hasQtyFieldTarget) return
    const current = parseInt(this.qtyFieldTarget.value || '1', 10)
    if (current > 1) {
      this.qtyFieldTarget.value = current - 1
      this.updateVariant()
    }
  }

  updateVariant() {
    const sizeId = this.hasSizeSelectTarget && this.sizeSelectTarget.value 
      ? parseInt(this.sizeSelectTarget.value) 
      : null
    const colorId = this.hasColorSelectTarget && this.colorSelectTarget.value 
      ? parseInt(this.colorSelectTarget.value) 
      : null

    const hasSizeSelect = this.hasSizeSelectTarget
    const hasColorSelect = this.hasColorSelectTarget
    const sizeSelected = sizeId !== null
    const colorSelected = colorId !== null

    let variant = null
    let imageVariant = null // Variante pour l'image (peut être différente si seule la couleur est sélectionnée)

    // Trouver une variante complète pour le stock/prix (nécessite toutes les options)
    if ((hasSizeSelect && !sizeSelected) || (hasColorSelect && !colorSelected)) {
      variant = null
    } else {
      // Trouver la variante correspondante
      // Une variante correspond si :
      // - Elle a la même taille (ou pas de sélection de taille)
      // - Elle a la même couleur (ou pas de sélection de couleur)
      // - ET elle a du stock
      variant = this.variantsValue.find(v => {
        // Vérifier la correspondance de la taille
        const matchSize = !hasSizeSelect 
          ? true 
          : (v.sizeId === sizeId)
        
        // Vérifier la correspondance de la couleur
        const matchColor = !hasColorSelect 
          ? true 
          : (v.colorId === colorId)
        
        // La variante doit correspondre ET avoir du stock
        return matchSize && matchColor && v.stock > 0
      })
    }

    // Pour l'image : si seule la couleur est sélectionnée, trouver une variante avec cette couleur
    if (colorSelected && !sizeSelected && hasColorSelect) {
      // Chercher la première variante avec cette couleur (n'importe quelle taille)
      imageVariant = this.variantsValue.find(v => v.colorId === colorId)
    } else if (variant) {
      // Si on a une variante complète, l'utiliser pour l'image aussi
      imageVariant = variant
    }

    const qty = this.hasQtyFieldTarget 
      ? Math.max(1, parseInt(this.qtyFieldTarget.value || '1', 10)) 
      : 1

    if (variant && variant.stock > 0) {
      // Variante valide avec stock
      if (this.hasVariantInputTarget) {
        this.variantInputTarget.value = variant.id
      }
      if (this.hasAddButtonTarget) {
        this.addButtonTarget.disabled = false
      }

      // Mettre à jour le stock
      if (this.hasStockValueTarget) {
        this.stockValueTarget.textContent = variant.stock
      }
      if (this.hasStockHintTarget) {
        this.stockHintTarget.style.display = 'block'
      }

      // Mettre à jour la quantité max
      if (this.hasQtyFieldTarget) {
        this.qtyFieldTarget.max = variant.stock
        let current = parseInt(this.qtyFieldTarget.value || '1', 10)
        if (current > variant.stock) {
          current = variant.stock
        }
        if (current < 1 || isNaN(current)) {
          current = 1
        }
        this.qtyFieldTarget.value = current
      }

      // Mettre à jour le prix unitaire
      if (this.hasUnitPriceValueTarget) {
        this.unitPriceValueTarget.textContent = this.formatPrice(variant.price)
      }

      // Mettre à jour le prix total
      if (this.hasPriceDisplayTarget) {
        this.priceDisplayTarget.textContent = this.formatPrice(variant.price * qty)
      }

    }

    // Mettre à jour l'image indépendamment de la variante complète
    // (peut changer même si seule la couleur est sélectionnée)
    let imageUrlToUse = null
    if (imageVariant && imageVariant.imageUrl && imageVariant.imageUrl !== this.defaultImageUrlValue) {
      imageUrlToUse = imageVariant.imageUrl
    } else if (this.initialImageSrc) {
      // Revenir à l'image initiale si aucune variante d'image trouvée
      imageUrlToUse = this.initialImageSrc
    } else {
      // Fallback sur l'image par défaut
      imageUrlToUse = this.defaultImageUrlValue
    }

    // Mettre à jour l'image principale
    if (this.hasProductImageTarget && imageUrlToUse) {
      this.productImageTarget.src = imageUrlToUse
    }

    // Mettre à jour l'image du modal lightbox (si le modal existe)
    const modalImage = document.getElementById('productModalImage')
    if (modalImage && imageUrlToUse) {
      modalImage.src = imageUrlToUse
    }

    if (!variant) {
      // Aucune variante valide pour stock/prix (soit pas de sélection complète, soit pas de stock)
      if (this.hasVariantInputTarget) {
        this.variantInputTarget.value = ''
      }
      if (this.hasAddButtonTarget) {
        this.addButtonTarget.disabled = true
      }

      // Cacher le stock
      if (this.hasStockValueTarget) {
        this.stockValueTarget.textContent = '0'
      }
      if (this.hasStockHintTarget) {
        this.stockHintTarget.style.display = 'none'
      }

      // Réinitialiser la quantité max
      if (this.hasQtyFieldTarget) {
        this.qtyFieldTarget.max = 0
        // Réinitialiser la quantité à 1 si elle est invalide
        const current = parseInt(this.qtyFieldTarget.value || '1', 10)
        if (current < 1 || isNaN(current)) {
          this.qtyFieldTarget.value = 1
        }
      }

      // Afficher le prix minimum si des variantes existent
      if (this.hasPriceDisplayTarget) {
        if (this.variantsValue && this.variantsValue.length > 0) {
          // Filtrer les variantes avec stock pour calculer le prix minimum
          const variantsWithStock = this.variantsValue.filter(v => v.stock > 0)
          if (variantsWithStock.length > 0) {
            const minPrice = Math.min(...variantsWithStock.map(v => v.price))
            const hasMultiple = variantsWithStock.length > 1
            this.priceDisplayTarget.textContent = hasMultiple 
              ? 'À partir de ' + this.formatPrice(minPrice * qty) 
              : this.formatPrice(minPrice * qty)
          } else {
            // Toutes les variantes sont en rupture
            this.priceDisplayTarget.textContent = 'Rupture de stock'
          }
        } else {
          // Pas de variantes disponibles
          this.priceDisplayTarget.textContent = 'Prix non disponible'
        }
      }

      // Ne pas toucher à l'image si aucune variante n'est sélectionnée
      // (garder l'image initiale chargée par image_tag)
    }
  }

  formatPrice(cents) {
    const amount = cents / 100.0
    const formatted = amount === Math.floor(amount) 
      ? amount.toString() 
      : amount.toFixed(2)
    return formatted.replace('.', ',') + '€'
  }
}

