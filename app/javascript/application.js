// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
// Bootstrap avant controllers pour que window.bootstrap soit disponible dès connect() (toast, etc.)
import "bootstrap"
import "controllers"
// Import des fonctions de validation harmonisées pour les formulaires d'adhésion
import { validateHealthQuestions, markHealthQuestionInvalid, markHealthQuestionValid, validateField } from "membership_form_validation"
// Exporter globalement pour utilisation dans les scripts inline
window.validateHealthQuestions = validateHealthQuestions
window.markHealthQuestionInvalid = markHealthQuestionInvalid
window.markHealthQuestionValid = markHealthQuestionValid
window.validateField = validateField

// PWA: enregistrement du service worker et mise à jour automatique
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").then((reg) => {
      // Vérifier les mises à jour périodiquement (toutes les 60 s) quand l'app est ouverte
      setInterval(() => reg.update(), 60_000)
    }).catch((err) => console.warn("SW registration failed:", err))
    // Quand un nouveau SW a pris le relais (après un déploiement), recharger pour utiliser la nouvelle version
    navigator.serviceWorker.addEventListener("controllerchange", () => window.location.reload())
  })
}
