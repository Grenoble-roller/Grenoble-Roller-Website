import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropZone", "fileInput", "previewGrid", "previewContainer"]
  static values = { 
    maxSize: Number,
    acceptedTypes: String
  }

  connect() {
    this.setupDragAndDrop()
  }

  // ==========================================
  // DRAG & DROP
  // ==========================================

  setupDragAndDrop() {
    // Prévenir le comportement par défaut du navigateur
    ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.preventDefaults, false)
    })
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  handleDragOver(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.add("border-primary", "bg-light")
  }

  handleDragLeave(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("border-primary", "bg-light")
  }

  handleDrop(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("border-primary", "bg-light")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.handleFiles({ target: { files: files } })
    }
  }

  // ==========================================
  // FILE SELECTION
  // ==========================================

  triggerFileInput(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Essayer d'abord avec le target Stimulus
    if (this.hasFileInputTarget && this.fileInputTarget) {
      this.fileInputTarget.click()
      return
    }
    
    // Fallback : chercher directement l'input file dans le controller
    const fileInput = this.element.querySelector('input[type="file"]')
    if (fileInput) {
      fileInput.click()
      return
    }
    
    // Dernier fallback : chercher par ID
    const fileInputById = document.getElementById('product_image_input')
    if (fileInputById) {
      fileInputById.click()
      return
    }
    
    console.error("Image upload: No file input found")
  }

  handleFiles(event) {
    const files = Array.from(event.target.files || event.dataTransfer?.files || [])
    
    if (files.length === 0) return

    files.forEach(file => {
      if (this.validateFile(file)) {
        this.previewFile(file)
      }
    })
  }

  // ==========================================
  // VALIDATION FICHIER
  // ==========================================

  validateFile(file) {
    // Vérifier le type
    const acceptedTypes = this.acceptedTypesValue.split(",")
    if (!acceptedTypes.includes(file.type)) {
      this.showError(`Type de fichier non accepté : ${file.type}`)
      return false
    }

    // Vérifier la taille
    if (this.maxSizeValue && file.size > this.maxSizeValue) {
      const maxSizeMB = (this.maxSizeValue / 1024 / 1024).toFixed(1)
      this.showError(`Fichier trop volumineux. Maximum : ${maxSizeMB}MB`)
      return false
    }

    return true
  }

  // ==========================================
  // PREVIEW IMAGE
  // ==========================================

  previewFile(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const imageUrl = e.target.result
      this.addPreviewImage(file, imageUrl)
    }

    reader.onerror = () => {
      this.showError("Erreur lors de la lecture du fichier")
    }

    reader.readAsDataURL(file)
  }

  addPreviewImage(file, imageUrl) {
    // Afficher la zone de preview
    if (this.hasPreviewGridTarget) {
      this.previewGridTarget.style.display = "block"
    }

    // Créer l'élément preview
    const previewItem = document.createElement("div")
    previewItem.className = "col-md-3 col-sm-6"
    previewItem.dataset.fileName = file.name

    previewItem.innerHTML = `
      <div class="position-relative">
        <img src="${imageUrl}" 
             class="img-thumbnail w-100" 
             style="height: 150px; object-fit: cover;"
             alt="Preview">
        <div class="position-absolute top-0 end-0 m-2">
          <button type="button" 
                  class="btn btn-sm btn-danger"
                  data-action="click->image-upload#removePreview"
                  title="Supprimer">
            <i class="bi bi-trash"></i>
          </button>
        </div>
        <div class="position-absolute bottom-0 start-0 end-0 bg-dark bg-opacity-75 text-white p-2">
          <small class="d-block text-truncate">${file.name}</small>
          <small class="text-muted">${this.formatFileSize(file.size)}</small>
        </div>
      </div>
    `

    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.appendChild(previewItem)
    }
  }

  removePreview(event) {
    const previewItem = event.target.closest(".col-md-3")
    if (previewItem) {
      previewItem.remove()
      
      // Masquer la zone de preview si vide
      if (this.hasPreviewContainerTarget && 
          this.previewContainerTarget.children.length === 0) {
        if (this.hasPreviewGridTarget) {
          this.previewGridTarget.style.display = "none"
        }
      }
    }
  }

  removeCurrentImage(event) {
    if (confirm("Êtes-vous sûr de vouloir supprimer cette image ?")) {
      // Ajouter un champ hidden pour indiquer la suppression
      const hiddenInput = document.createElement("input")
      hiddenInput.type = "hidden"
      hiddenInput.name = "remove_image"
      hiddenInput.value = "true"
      this.element.appendChild(hiddenInput)

      // Masquer l'image
      const imageContainer = event.target.closest(".image-preview-current")
      if (imageContainer) {
        imageContainer.style.display = "none"
      }
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
  }

  showError(message) {
    // Créer une alerte Bootstrap
    const alertDiv = document.createElement("div")
    alertDiv.className = "alert alert-danger alert-dismissible fade show position-fixed"
    alertDiv.style.cssText = "top: 20px; right: 20px; z-index: 9999; min-width: 300px;"
    alertDiv.innerHTML = `
      <strong>Erreur :</strong> ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `
    document.body.appendChild(alertDiv)

    // Retirer après 5 secondes
    setTimeout(() => {
      alertDiv.remove()
    }, 5000)
  }
}

