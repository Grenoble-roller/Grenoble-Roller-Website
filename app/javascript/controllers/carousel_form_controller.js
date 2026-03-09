import { Controller } from "@hotwired/stimulus"

// Live image preview for carousel slide form: original format + 1900×500 ratio preview
export default class extends Controller {
  static targets = ["fileInput", "imagePreview", "imagePreviewPlaceholder", "ratioPreview", "ratioPreviewPlaceholder"]

  connect() {
    this._boundPreviewFile = this.previewFile.bind(this)
    if (this.hasFileInputTarget) {
      this.fileInputTarget.addEventListener("change", this._boundPreviewFile)
    }
  }

  disconnect() {
    if (this.hasFileInputTarget && this._boundPreviewFile) {
      this.fileInputTarget.removeEventListener("change", this._boundPreviewFile)
    }
    this.revokeObjectUrl()
  }

  previewFile(event) {
    const file = event.target.files?.[0]
    if (!file || !file.type.startsWith("image/")) {
      this.clearPreviews()
      return
    }

    this.revokeObjectUrl()
    const url = URL.createObjectURL(file)
    this._currentObjectUrl = url

    const img = new Image()
    img.onload = () => {
      this.showImagePreview(url)
      this.showRatioPreview(url)
    }
    img.onerror = () => {
      this.clearPreviews()
      URL.revokeObjectURL(url)
    }
    img.src = url
  }

  showImagePreview(url) {
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.src = url
      this.imagePreviewTarget.alt = "Aperçu du fichier sélectionné"
      this.imagePreviewTarget.classList.remove("d-none")
      this.imagePreviewTarget.style.display = "block"
      if (this.hasImagePreviewPlaceholderTarget) {
        this.imagePreviewPlaceholderTarget.style.display = "none"
      }
    }
  }

  showRatioPreview(url) {
    if (this.hasRatioPreviewTarget) {
      this.ratioPreviewTarget.src = url
      this.ratioPreviewTarget.alt = "Aperçu au ratio 1900×500"
      this.ratioPreviewTarget.classList.remove("d-none")
      this.ratioPreviewTarget.style.display = "block"
      if (this.hasRatioPreviewPlaceholderTarget) {
        this.ratioPreviewPlaceholderTarget.style.display = "none"
      }
    }
  }

  clearPreviews() {
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.removeAttribute("src")
      this.imagePreviewTarget.classList.add("d-none")
      this.imagePreviewTarget.style.display = "none"
      if (this.hasImagePreviewPlaceholderTarget) {
        this.imagePreviewPlaceholderTarget.style.display = ""
      }
    }
    if (this.hasRatioPreviewTarget) {
      this.ratioPreviewTarget.removeAttribute("src")
      this.ratioPreviewTarget.classList.add("d-none")
      this.ratioPreviewTarget.style.display = "none"
      if (this.hasRatioPreviewPlaceholderTarget) {
        this.ratioPreviewPlaceholderTarget.style.display = ""
      }
    }
  }

  revokeObjectUrl() {
    if (this._currentObjectUrl) {
      URL.revokeObjectURL(this._currentObjectUrl)
      this._currentObjectUrl = null
    }
  }
}
