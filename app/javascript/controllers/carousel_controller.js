import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
// By default no autoplay (accessibility 2023-2026). Set data-carousel-autoplay-value="true" to enable.
export default class extends Controller {
  static values = { autoplay: { type: Boolean, default: false } }

  connect() {
    requestAnimationFrame(() => {
      this.initializeCarousel()
    })
  }

  initializeCarousel() {
    const waitForBootstrap = (callback, maxAttempts = 50) => {
      if (window.bootstrap && window.bootstrap.Carousel) {
        callback(window.bootstrap)
      } else if (maxAttempts > 0) {
        setTimeout(() => waitForBootstrap(callback, maxAttempts - 1), 100)
      } else {
        console.error('Bootstrap Carousel is not available after waiting', window.bootstrap)
      }
    }

    waitForBootstrap((bootstrap) => {
      const carouselItems = this.element.querySelectorAll('.carousel-item')
      if (carouselItems.length < 2) {
        return
      }

      let carousel = bootstrap.Carousel.getInstance(this.element)
      const autoplay = this.autoplayValue

      if (!carousel) {
        const interval = autoplay ? (parseInt(this.element.dataset.bsInterval) || 5000) : false
        carousel = new bootstrap.Carousel(this.element, {
          interval,
          ride: autoplay ? 'carousel' : false,
          wrap: true,
          pause: autoplay ? false : true,
          keyboard: true,
          touch: true
        })
      }

      this.carouselInstance = carousel

      if (autoplay && this.carouselInstance && !this.carouselInstance._interval) {
        setTimeout(() => {
          if (this.carouselInstance) {
            this.carouselInstance.cycle()
          }
        }, 200)
      }
    })
  }

  disconnect() {
    if (this.carouselInstance) {
      this.carouselInstance.dispose()
      this.carouselInstance = null
    }
  }
}
