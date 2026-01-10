import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "nameField", "nameCharCount", "nameFeedback",
    "slugField", "slugFeedback",
    "categoryField", "categoryFeedback",
    "priceField", "priceFeedback",
    "descriptionField",
    "metaTitleField", "metaTitleCharCount",
    "metaDescriptionField", "metaDescriptionCharCount",
    "autoSection", "previewBox", "variantCount", "previewSkus", "previewWarning",
    "statusBar", "statusMessage", "lastSave", "lastSaveTime",
    "saveButton", "publishButton", "draftButton",
    "tabs", "accordion"
  ]
  static values = { 
    autoSaveUrl: String,
    previewVariantsUrl: String
  }

  connect() {
    this.autoSaveTimeout = null
    this.lastSaveTime = null
    
    // Initialiser les compteurs de caractères
    this.updateCharCounts()
    
    // Validation initiale
    this.validateAll()
    
    // Auto-save si URL fournie
    if (this.autoSaveUrlValue) {
      this.setupAutoSave()
    }
    
    // Setup preview variants
    if (this.hasPreviewVariantsUrlValue) {
      this.setupPreviewVariants()
    }
  }

  // ==========================================
  // VALIDATION EN TEMPS RÉEL
  // ==========================================

  validateField(event) {
    const field = event?.target
    if (!field || !field.name) return
    
    const fieldName = field.name
    
    let isValid = true
    let errorMessage = ""

    switch(fieldName) {
      case "product[name]":
        if (!this.hasNameFieldTarget) return
        isValid = this.validateName(field.value)
        if (!isValid) {
          errorMessage = "Le nom doit contenir au moins 3 caractères et ne peut pas dépasser 140 caractères"
        }
        this.updateFieldState(this.nameFieldTarget, isValid, errorMessage, this.nameFeedbackTarget)
        if (this.hasNameCharCountTarget) {
          this.updateCharCount(field.value, this.nameCharCountTarget, 140)
        }
        break

      case "product[slug]":
        if (!this.hasSlugFieldTarget) return
        isValid = this.validateSlugValue(field.value)
        if (!isValid) {
          errorMessage = "Le slug doit contenir uniquement des lettres minuscules, chiffres et tirets"
        }
        this.updateFieldState(this.slugFieldTarget, isValid, errorMessage, this.slugFeedbackTarget)
        break

      case "product[category_id]":
        if (!this.hasCategoryFieldTarget) return
        isValid = field.value !== ""
        if (!isValid) {
          errorMessage = "Veuillez sélectionner une catégorie"
        }
        this.updateFieldState(this.categoryFieldTarget, isValid, errorMessage, this.categoryFeedbackTarget)
        break

      case "product[price_cents]":
        if (!this.hasPriceFieldTarget) return
        isValid = this.validatePrice(field.value)
        if (!isValid) {
          errorMessage = "Le prix doit être supérieur à 0"
        }
        this.updateFieldState(this.priceFieldTarget, isValid, errorMessage, this.priceFeedbackTarget)
        break
    }

    this.updateSubmitButtons()
  }

  validateName(value) {
    return value.length >= 3 && value.length <= 140
  }

  validateSlugValue(value) {
    if (value === "") return true // Slug optionnel, généré auto si vide
    return /^[a-z0-9-]+$/.test(value)
  }

  validatePrice(value) {
    const price = parseFloat(value)
    return !isNaN(price) && price > 0
  }

  validateAll() {
    if (this.hasNameFieldTarget && this.nameFieldTarget) {
      this.validateField({ target: this.nameFieldTarget })
    }
    if (this.hasSlugFieldTarget && this.slugFieldTarget) {
      this.validateField({ target: this.slugFieldTarget })
    }
    if (this.hasCategoryFieldTarget && this.categoryFieldTarget) {
      this.validateField({ target: this.categoryFieldTarget })
    }
    if (this.hasPriceFieldTarget && this.priceFieldTarget) {
      this.validateField({ target: this.priceFieldTarget })
    }
  }

  updateFieldState(field, isValid, errorMessage, feedbackTarget) {
    if (!field) return
    
    if (isValid) {
      field.classList.remove("is-invalid")
      field.classList.add("is-valid")
      if (feedbackTarget) {
        feedbackTarget.textContent = ""
      }
    } else {
      field.classList.remove("is-valid")
      field.classList.add("is-invalid")
      if (feedbackTarget) {
        feedbackTarget.textContent = errorMessage
      }
    }
  }

  updateSubmitButtons() {
    const allValid = this.isFormValid()
    
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = !allValid
    }
    if (this.hasPublishButtonTarget) {
      this.publishButtonTarget.disabled = !allValid
    }
    if (this.hasDraftButtonTarget) {
      // Brouillon peut toujours être sauvegardé
      this.draftButtonTarget.disabled = false
    }
  }

  isFormValid() {
    const nameValid = !this.hasNameFieldTarget || this.nameFieldTarget.classList.contains("is-valid")
    const slugValid = !this.hasSlugFieldTarget || this.slugFieldTarget.classList.contains("is-valid")
    const categoryValid = !this.hasCategoryFieldTarget || this.categoryFieldTarget.classList.contains("is-valid")
    const priceValid = !this.hasPriceFieldTarget || this.priceFieldTarget.classList.contains("is-valid")
    
    return nameValid && slugValid && categoryValid && priceValid
  }

  // ==========================================
  // COMPTEURS DE CARACTÈRES
  // ==========================================

  updateCharCounts() {
    if (this.hasNameFieldTarget) {
      this.updateCharCount(this.nameFieldTarget.value, this.nameCharCountTarget, 140)
    }
    if (this.hasMetaTitleFieldTarget) {
      this.updateCharCount(this.metaTitleFieldTarget.value, this.metaTitleCharCountTarget, 60)
    }
    if (this.hasMetaDescriptionFieldTarget) {
      this.updateCharCount(this.metaDescriptionFieldTarget.value, this.metaDescriptionCharCountTarget, 160)
    }
  }

  updateCharCount(event) {
    const field = event.target
    let target, maxLength

    if (field === this.nameFieldTarget) {
      target = this.nameCharCountTarget
      maxLength = 140
    } else if (field === this.metaTitleFieldTarget) {
      target = this.metaTitleCharCountTarget
      maxLength = 60
    } else if (field === this.metaDescriptionFieldTarget) {
      target = this.metaDescriptionCharCountTarget
      maxLength = 160
    }

    if (target) {
      this.updateCharCount(field.value, target, maxLength)
    }
  }

  updateCharCount(value, target, maxLength) {
    if (target) {
      const count = value.length
      target.textContent = `${count}/${maxLength}`
      
      if (count > maxLength * 0.9) {
        target.classList.add("text-warning")
        target.classList.remove("text-muted")
      } else {
        target.classList.remove("text-warning")
        target.classList.add("text-muted")
      }
    }
  }

  // ==========================================
  // FORMATAGE PRIX
  // ==========================================

  formatPrice(event) {
    const field = event.target
    const value = parseFloat(field.value)
    
    if (!isNaN(value) && value > 0) {
      // Afficher le prix en euros dans un tooltip ou helper text
      const priceInEuros = (value / 100).toFixed(2)
      // Vous pouvez ajouter un feedback visuel ici
    }
  }

  // ==========================================
  // AUTO-SAVE
  // ==========================================

  setupAutoSave() {
    // Auto-save toutes les 30 secondes si des modifications ont été faites
    setInterval(() => {
      if (this.hasUnsavedChanges()) {
        this.performAutoSave()
      }
    }, 30000) // 30 secondes
  }

  autoSave(event) {
    // Debounce pour éviter trop de requêtes
    clearTimeout(this.autoSaveTimeout)
    
    this.autoSaveTimeout = setTimeout(() => {
      if (this.autoSaveUrlValue) {
        this.performAutoSave()
      }
    }, 2000) // 2 secondes après la dernière modification
  }

  hasUnsavedChanges() {
    // Vérifier si des champs ont été modifiés
    // Simplifié pour l'instant
    return true
  }

  async performAutoSave() {
    if (!this.autoSaveUrlValue) return

    this.showStatusBar("Enregistrement automatique...")
    
    const formData = new FormData(this.element)
    formData.append("save_draft", "true")

    try {
      const response = await fetch(this.autoSaveUrlValue, {
        method: "PATCH",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.lastSaveTime = new Date()
        this.showStatusBar("Enregistré automatiquement", true)
      } else {
        const errorData = await response.json().catch(() => ({ errors: ["Erreur lors de l'enregistrement"] }))
        console.error("Auto-save error:", errorData)
        this.showStatusBar("Erreur lors de l'enregistrement", false)
      }
    } catch (error) {
      console.error("Auto-save error:", error)
      this.showStatusBar("Erreur de connexion", false)
    }
  }

  showStatusBar(message, success = false) {
    if (this.hasStatusBarTarget) {
      this.statusBarTarget.style.display = "block"
      
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = message
      }

      if (success && this.hasLastSaveTarget && this.lastSaveTime) {
        this.lastSaveTarget.style.display = "inline-block"
        if (this.hasLastSaveTimeTarget) {
          const timeStr = this.lastSaveTime.toLocaleTimeString("fr-FR")
          this.lastSaveTimeTarget.textContent = timeStr
        }
      }

      // Masquer après 5 secondes si succès
      if (success) {
        setTimeout(() => {
          this.statusBarTarget.style.display = "none"
        }, 5000)
      }
    }
  }

  // ==========================================
  // PREVIEW VARIANTES
  // ==========================================

  setupPreviewVariants() {
    // Setup initial si nécessaire
  }

  async previewVariants(event) {
    // Collecter les option_value_ids sélectionnés
    const checkedOptionValues = Array.from(
      document.querySelectorAll('input[name="option_value_ids[]"]:checked')
    ).map(el => el.value)

    if (checkedOptionValues.length === 0) {
      if (this.hasPreviewBoxTarget) {
        this.previewBoxTarget.style.display = "none"
      }
      return
    }

    if (!this.hasPreviewVariantsUrlValue) {
      // Fallback vers l'URL par défaut
      const url = this.element.dataset.previewVariantsUrl || 
                  "/admin-panel/products/preview_variants"
      
      try {
        const response = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify({ option_value_ids: checkedOptionValues })
        })

        const data = await response.json()
        this.updatePreview(data)
      } catch (error) {
        console.error("Preview variants error:", error)
      }
    } else {
      // Utiliser l'URL configurée
      try {
        const response = await fetch(this.previewVariantsUrlValue, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify({ option_value_ids: checkedOptionValues })
        })

        const data = await response.json()
        this.updatePreview(data)
      } catch (error) {
        console.error("Preview variants error:", error)
      }
    }
  }

  updatePreview(data) {
    if (this.hasPreviewBoxTarget) {
      this.previewBoxTarget.style.display = "block"
    }

    if (this.hasVariantCountTarget) {
      this.variantCountTarget.textContent = data.count || 0
    }

    if (this.hasPreviewSkusTarget) {
      const skus = data.preview_skus || []
      this.previewSkusTarget.textContent = 
        skus.length > 0 
          ? `Exemples SKU : ${skus.slice(0, 5).join(", ")}${skus.length > 5 ? "..." : ""}`
          : "Aucun SKU généré"
    }

    if (this.hasPreviewWarningTarget) {
      if (data.warning) {
        this.previewWarningTarget.textContent = data.warning
        this.previewWarningTarget.style.display = "block"
      } else {
        this.previewWarningTarget.style.display = "none"
      }
    }
  }

  // ==========================================
  // TOGGLE VARIANT MODE
  // ==========================================

  toggleVariantMode(event) {
    const mode = event.target.value
    
    if (this.hasAutoSectionTarget) {
      if (mode === "auto") {
        this.autoSectionTarget.style.display = "block"
      } else {
        this.autoSectionTarget.style.display = "none"
      }
    }
  }

  // ==========================================
  // VALIDATION SLUG
  // ==========================================

  validateSlug(event) {
    const field = event?.target
    if (!field) return
    
    const value = field.value?.trim() || ""

    // Si vide, générer automatiquement depuis le nom
    if (value === "" && this.hasNameFieldTarget && this.nameFieldTarget) {
      const name = this.nameFieldTarget.value || ""
      if (name) {
        const autoSlug = name
          .toLowerCase()
          .normalize("NFD")
          .replace(/[\u0300-\u036f]/g, "") // Supprimer accents
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-+|-+$/g, "")
        
        field.value = autoSlug
        this.validateField({ target: field })
      }
    } else {
      this.validateField({ target: field })
    }
  }
}

