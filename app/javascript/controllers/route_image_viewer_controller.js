import { Controller } from "@hotwired/stimulus"
import PhotoSwipeLightbox from "photoswipe/lightbox"
import PhotoSwipe from "photoswipe"

/**
 * Event cover + loop map gallery via PhotoSwipe 5.
 * Overlay + pinch/wheel zoom on mobile and desktop (no native new-tab path).
 *
 * Mount on a parent that wraps all `a.pswp-gallery-item` links (event show article).
 */
export default class extends Controller {
  connect() {
    this._dimensionsReady = this.#hydrateDimensions()
    this.lightbox = new PhotoSwipeLightbox({
      gallery: this.element,
      children: "a.pswp-gallery-item",
      pswpModule: PhotoSwipe,
      showHideAnimationType: "fade",
      bgOpacity: 0.92,
      wheelToZoom: true,
      openPromise: () => this._dimensionsReady
    })
    this.lightbox.init()
  }

  disconnect() {
    this.lightbox?.destroy()
    this.lightbox = null
  }

  async #hydrateDimensions() {
    const links = this.element.querySelectorAll("a.pswp-gallery-item")
    await Promise.all(
      Array.from(links).map(async (anchor) => {
        if (anchor.dataset.pswpWidth && anchor.dataset.pswpHeight) return

        const src = anchor.getAttribute("href")
        if (!src) return

        const image = new Image()
        image.src = src
        try {
          await image.decode()
          anchor.dataset.pswpWidth = String(image.naturalWidth || 1920)
          anchor.dataset.pswpHeight = String(image.naturalHeight || 1080)
        } catch {
          anchor.dataset.pswpWidth = "1920"
          anchor.dataset.pswpHeight = "1080"
        }
      })
    )
  }
}
