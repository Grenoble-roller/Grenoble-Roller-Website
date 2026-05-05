import { Controller } from "@hotwired/stimulus"

// Generic media preview:
// - master preview (contain, original file)
// - one or many surface previews (cover, fixed ratio containers)
export default class extends Controller {
  static targets = [
    "fileInput",
    "masterImage",
    "masterPlaceholder",
    "surfaceImage",
    "surfacePlaceholder"
  ]

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
    img.onload = () => this.showPreviews(url)
    img.onerror = () => {
      this.clearPreviews()
      URL.revokeObjectURL(url)
    }
    img.src = url
  }

  showPreviews(url) {
    if (this.hasMasterImageTarget) {
      this.masterImageTarget.src = url
      this.masterImageTarget.classList.remove("d-none")
      this.masterImageTarget.style.display = "block"
    }
    if (this.hasMasterPlaceholderTarget) {
      this.masterPlaceholderTarget.style.display = "none"
    }

    this.surfaceImageTargets.forEach((target) => {
      target.src = url
      target.classList.remove("d-none")
      target.style.display = "block"
    })
    this.surfacePlaceholderTargets.forEach((target) => {
      target.style.display = "none"
    })
  }

  clearPreviews() {
    if (this.hasMasterImageTarget) {
      this.masterImageTarget.removeAttribute("src")
      this.masterImageTarget.classList.add("d-none")
      this.masterImageTarget.style.display = "none"
    }
    if (this.hasMasterPlaceholderTarget) {
      this.masterPlaceholderTarget.style.display = ""
    }

    this.surfaceImageTargets.forEach((target) => {
      target.removeAttribute("src")
      target.classList.add("d-none")
      target.style.display = "none"
    })
    this.surfacePlaceholderTargets.forEach((target) => {
      target.style.display = ""
    })
  }

  revokeObjectUrl() {
    if (this._currentObjectUrl) {
      URL.revokeObjectURL(this._currentObjectUrl)
      this._currentObjectUrl = null
    }
  }
}
