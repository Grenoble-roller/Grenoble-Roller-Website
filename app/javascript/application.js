// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
// Bootstrap est chargé via importmap (bootstrap.bundle.min.js) et expose window.bootstrap automatiquement
// On l'importe pour s'assurer qu'il est chargé, mais on n'utilise pas la valeur retournée
// car le bundle expose directement window.bootstrap
import "bootstrap"
// Import des fonctions de validation harmonisées pour les formulaires d'adhésion
import { validateHealthQuestions, markHealthQuestionInvalid, markHealthQuestionValid, validateField } from "membership_form_validation"
// Exporter globalement pour utilisation dans les scripts inline
window.validateHealthQuestions = validateHealthQuestions
window.markHealthQuestionInvalid = markHealthQuestionInvalid
window.markHealthQuestionValid = markHealthQuestionValid
window.validateField = validateField
