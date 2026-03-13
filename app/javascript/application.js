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
