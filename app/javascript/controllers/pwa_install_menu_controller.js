import { Controller } from "@hotwired/stimulus"

// Affiche l'entrée de menu "Installer l'application" quand l'app n'est pas déjà ouverte en mode PWA.
// Au clic : déclenche l'installation (Chrome) ou affiche les instructions (iOS).
// Bonne pratique web.dev : bouton d'install dans le header/menu pour les utilisateurs engagés.
export default class extends Controller {
  connect() {
    if (this.#isStandalone()) {
      this.element.style.display = "none"
      return
    }
    this.element.style.display = ""
  }

  #isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }

  #isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  async install(event) {
    event.preventDefault()
    const prompt = window.__pwaInstallPrompt
    if (prompt) {
      try {
        await prompt.prompt()
        const { outcome } = await prompt.userChoice
        if (outcome === "accepted") window.__pwaInstallPrompt = null
      } catch (e) {
        console.warn("PWA install prompt failed:", e)
      }
      return
    }
    if (this.#isIOS()) {
      alert(
        "Pour installer l'application sur iPhone/iPad :\n\n" +
        "1. Touchez le bouton Partager (icône carré avec flèche)\n" +
        "2. Faites défiler puis touchez « Sur l'écran d'accueil »\n" +
        "3. Touchez « Ajouter »"
      )
    }
  }
}
