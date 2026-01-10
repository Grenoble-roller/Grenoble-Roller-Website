import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
  connect() {
    // Utiliser requestAnimationFrame pour s'assurer que le DOM est prêt
    // Cela résout les problèmes de timing avec Turbo
    requestAnimationFrame(() => {
      this.initializeCarousel()
    })
  }

  initializeCarousel() {
    // Attendre que Bootstrap soit disponible sur window
    // Le bundle bootstrap.bundle.min.js expose window.bootstrap automatiquement
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
      // Vérifier qu'il y a plusieurs slides avant d'initialiser
      const carouselItems = this.element.querySelectorAll('.carousel-item')
      if (carouselItems.length < 2) {
        console.log('Carousel needs at least 2 items to cycle')
        return
      }
      
      // Vérifier si une instance existe déjà (créée par Bootstrap via data-bs-ride)
      let carousel = bootstrap.Carousel.getInstance(this.element)
      
      if (!carousel) {
        // Récupérer l'interval depuis data-bs-interval ou utiliser la valeur par défaut
        const interval = parseInt(this.element.dataset.bsInterval) || 5000
        
        // Initialiser le carousel avec pause désactivée pour qu'il tourne en continu
        carousel = new bootstrap.Carousel(this.element, {
          interval: interval,
          ride: 'carousel',
          wrap: true,
          pause: false, // Désactiver la pause au survol pour rotation continue
          keyboard: true,
          touch: true
        })
      } else {
        // Si une instance existe déjà, s'assurer qu'elle tourne
        // et mettre à jour les options si nécessaire
        const interval = parseInt(this.element.dataset.bsInterval) || 5000
        if (carousel._config.interval !== interval) {
          carousel._config.interval = interval
          carousel._config.defaultInterval = interval
        }
        carousel._config.pause = false
      }
      
      // Stocker l'instance pour pouvoir la nettoyer si nécessaire
      this.carouselInstance = carousel
      
      // Démarrer automatiquement le cycle du carousel
      // La méthode cycle() démarre la rotation automatique
      setTimeout(() => {
        if (this.carouselInstance && !this.carouselInstance._interval) {
          this.carouselInstance.cycle()
        }
      }, 200)
    })
  }

  disconnect() {
    // Nettoyer l'instance du carousel si elle existe
    if (this.carouselInstance) {
      this.carouselInstance.dispose()
      this.carouselInstance = null
    }
  }
}
