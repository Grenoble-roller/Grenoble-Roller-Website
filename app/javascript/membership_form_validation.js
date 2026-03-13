// Fonctions de validation harmonisées pour les formulaires d'adhésion
// Utilisé par adult_form.html.erb et child_form.html.erb

/**
 * Marquer visuellement une question de santé comme invalide
 * Style uniforme : bordure rouge + fond rouge clair (géré par CSS)
 */
export function markHealthQuestionInvalid(questionItem) {
  if (questionItem) {
    questionItem.classList.add('is-invalid');
    // Les styles CSS gèrent maintenant les couleurs via .is-invalid
  }
}

/**
 * Retirer le marquage d'erreur d'une question de santé
 */
export function markHealthQuestionValid(questionItem) {
  if (questionItem) {
    questionItem.classList.remove('is-invalid');
  }
}

/**
 * Valider toutes les questions de santé
 * Retourne true si toutes les questions sont répondues
 * @param {string} formId - ID du formulaire (pour les IDs uniques, vide par défaut)
 */
export function validateHealthQuestions(formId = '') {
  let allHealthAnswered = true;
  const unansweredQuestions = [];
  
  for (let i = 1; i <= 9; i++) {
    // Construire les IDs avec ou sans formId
    const yesId = formId ? `health_q${i}_yes${formId}` : `health_q${i}_yes`;
    const noId = formId ? `health_q${i}_no${formId}` : `health_q${i}_no`;
    
    const yesRadio = document.getElementById(yesId);
    const noRadio = document.getElementById(noId);
    const questionItem = yesRadio?.closest('.health-question-item');

    if (!yesRadio?.checked && !noRadio?.checked) {
      allHealthAnswered = false;
      unansweredQuestions.push(i);
      markHealthQuestionInvalid(questionItem);
    } else {
      markHealthQuestionValid(questionItem);
    }
  }

  // Afficher/masquer le message d'erreur
  const errorId = formId ? `health_questionnaire_error${formId}` : 'health_questionnaire_error';
  let errorDiv = document.getElementById(errorId);
  
  if (!allHealthAnswered) {
    if (!errorDiv) {
      const healthSection = document.querySelector('[id*="health"]')?.closest('.step-content') || 
                           document.querySelector('[id*="step-health"]') ||
                           document.querySelector('.form-section[id*="health"]');
      if (healthSection) {
        errorDiv = document.createElement('div');
        errorDiv.id = errorId;
        errorDiv.className = 'alert alert-danger mt-3';
        errorDiv.innerHTML = '<strong>Questionnaire incomplet :</strong> Veuillez répondre à toutes les questions de santé avant de continuer.';
        healthSection.appendChild(errorDiv);
      }
    }
  } else {
    if (errorDiv) {
      errorDiv.remove();
    }
  }

  return allHealthAnswered;
}

/**
 * Valider un champ de formulaire
 * Style uniforme : is-invalid / is-valid
 */
export function validateField(field, isValid, errorMessage = '') {
  if (!field) return;

  // Retirer les classes de validation précédentes
  field.classList.remove('is-invalid', 'is-valid');

  if (isValid) {
    field.classList.add('is-valid');
    // Retirer le message d'erreur s'il existe
    const errorDiv = field.parentElement?.querySelector('.invalid-feedback');
    if (errorDiv) {
      errorDiv.remove();
    }
  } else {
    field.classList.add('is-invalid');
    // Ajouter le message d'erreur s'il n'existe pas
    if (errorMessage && !field.parentElement?.querySelector('.invalid-feedback')) {
      const errorDiv = document.createElement('div');
      errorDiv.className = 'invalid-feedback';
      errorDiv.textContent = errorMessage;
      field.parentElement.appendChild(errorDiv);
    }
  }
}

// Les fonctions sont exportées pour être importées dans application.js
// Elles seront ensuite disponibles globalement via window.* dans application.js
// Note: Les fonctions sont aussi disponibles directement via window pour compatibilité avec les scripts inline
window.markHealthQuestionInvalid = markHealthQuestionInvalid;
window.markHealthQuestionValid = markHealthQuestionValid;
window.validateHealthQuestions = validateHealthQuestions;
window.validateField = validateField;
// Note: Les fonctions sont aussi disponibles directement via window pour compatibilité avec les scripts inline
window.markHealthQuestionInvalid = markHealthQuestionInvalid;
window.markHealthQuestionValid = markHealthQuestionValid;
window.validateHealthQuestions = validateHealthQuestions;
window.validateField = validateField;
