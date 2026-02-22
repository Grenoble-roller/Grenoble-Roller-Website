import { Controller } from "@hotwired/stimulus"

// Affiche une bannière "Installer l'app" sur mobile quand la PWA est installable.
// Chrome/Android : utilise beforeinstallprompt pour déclencher l'installation.
// iOS : affiche les instructions (Partager > Sur l'écran d'accueil).
export default class extends Controller {
  static targets = ["banner", "installButton", "dismissButton", "iosHint"]
  static values = {
    dismissDays: { type: Number, default: 7 }
  }

  connect() {
    this.installPrompt = null
    if (this.#isAlreadyInstalled()) return
    if (this.#isNeverShow()) return
    if (this.#isDismissedRecently()) return
    if (!this.#isMobileOrTablet()) return

    window.addEventListener("beforeinstallprompt", this.#onBeforeInstallPrompt.bind(this))
    this.#checkIOS()
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.#onBeforeInstallPrompt.bind(this))
  }

  #onBeforeInstallPrompt(event) {
    event.preventDefault()
    this.installPrompt = event
    window.__pwaInstallPrompt = event
    this.#showBanner(false) // false = variant Chrome (bouton Installer)
  }

  #checkIOS() {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
    if (isIOS && this.hasIosHintTarget) {
      this.iosHintTarget.hidden = false
      this.#showBanner(true) // true = variant iOS (instructions uniquement)
    }
  }

  #isAlreadyInstalled() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }

  #isNeverShow() {
    try {
      return localStorage.getItem("pwa_install_never") === "1"
    } catch {
      return false
    }
  }

  #isDismissedRecently() {
    if (this.#isNeverShow()) return true
    try {
      const raw = localStorage.getItem("pwa_install_dismissed")
      if (!raw) return false
      const at = parseInt(raw, 10)
      if (Number.isNaN(at)) return false
      return (Date.now() - at) < this.dismissDaysValue * 24 * 60 * 60 * 1000
    } catch {
      return false
    }
  }

  #isMobileOrTablet() {
    return window.matchMedia("(max-width: 1024px)").matches ||
      /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  }

  #showBanner(iosOnly) {
    if (!this.hasBannerTarget) return
    // Court délai pour ne pas superposer avec le bandeau cookies au premier chargement
    const show = () => {
      if (this.#isDismissedRecently()) return
      this.bannerTarget.hidden = false
      this.bannerTarget.style.display = "block"
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.hidden = !!iosOnly
      }
    }
    setTimeout(show, 2000)
  }

  async install() {
    const prompt = this.installPrompt ?? window.__pwaInstallPrompt
    if (!prompt) return
    try {
      await prompt.prompt()
      const { outcome } = await prompt.userChoice
      if (outcome === "accepted") this.#dismiss(false)
      window.__pwaInstallPrompt = null
      this.installPrompt = null
    } catch (e) {
      console.warn("PWA install prompt failed:", e)
    }
  }

  dismiss() {
    this.#dismiss(false)
  }

  neverShow() {
    this.#dismiss(true)
  }

  #dismiss(neverAgain = false) {
    try {
      if (neverAgain) {
        localStorage.setItem("pwa_install_never", "1")
      } else {
        localStorage.setItem("pwa_install_dismissed", String(Date.now()))
      }
    } catch {}
    if (this.hasBannerTarget) {
      this.bannerTarget.hidden = true
      this.bannerTarget.style.display = "none"
    }
  }
}
