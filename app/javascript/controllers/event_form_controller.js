import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
export default class extends Controller {
  static targets = ["levelSelect", "distanceInput", "routeSelect", "loopsCountInput"]

  connect() {
    // Si un parcours est déjà sélectionné au chargement, pré-remplir les champs
    if (this.hasRouteSelectTarget && this.routeSelectTarget.value) {
      this.loadRouteInfo(this.routeSelectTarget.value)
    }

    // Sauvegarde automatique conforme RGPD
    this.storageKey = 'event_draft'
    this.storageExpiryDays = 7 // Durée maximale RGPD pour données temporaires
    
    // Initialiser les données des parcours par boucle
    this.existingLoopRoutesData = {}
    this.loopRoutesLoaded = false // Flag pour indiquer si les données sont chargées
    
    // Restaurer les données sauvegardées au chargement
    this.restoreDraft()
    
    // Sauvegarder automatiquement lors des modifications
    this.setupAutoSave()
    
    // Nettoyer après soumission réussie
    this.setupCleanup()
    
    // Initialiser l'affichage de la distance totale
    this.updateTotalDistance()
    
    // Gérer la création de parcours depuis la modal
    this.setupRouteCreation()
    
    // Charger les parcours existants si on est en mode édition
    // IMPORTANT: Charger d'abord les données, puis initialiser les champs
    this.loadExistingLoopRoutes().then(() => {
      this.loopRoutesLoaded = true
      // Initialiser les champs de parcours par boucle (après chargement des données)
      this.updateLoopRoutesFields()
    })
  }

  loadRouteInfo(routeId) {
    if (!routeId || routeId === '') {
      // Si aucun parcours sélectionné, vider les champs
      if (this.hasLevelSelectTarget) {
        this.levelSelectTarget.value = ''
      }
      if (this.hasDistanceInputTarget) {
        this.distanceInputTarget.value = ''
      }
      return
    }

    // Récupérer les infos du parcours
    fetch(`/routes/${routeId}/info`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Erreur lors du chargement du parcours')
        }
        return response.json()
      })
      .then(data => {
        // Pré-remplir les champs
        if (this.hasLevelSelectTarget && data.level) {
          this.levelSelectTarget.value = data.level
        }
        if (this.hasDistanceInputTarget && data.distance_km) {
          this.distanceInputTarget.value = data.distance_km
        }
      })
      .catch(error => {
        console.error('Erreur:', error)
      })
  }

  routeChanged(event) {
    const routeId = event.target.value
    this.loadRouteInfo(routeId)
    // Sauvegarder après changement de parcours
    this.saveDraft()
  }

  // Calculer et afficher la distance totale (boucles × distance par boucle)
  loopsCountChanged() {
    this.updateTotalDistance()
    // Attendre que les données soient chargées avant de mettre à jour les champs
    if (this.loopRoutesLoaded) {
      this.updateLoopRoutesFields()
    } else {
      // Si les données ne sont pas encore chargées, attendre qu'elles le soient
      this.loadExistingLoopRoutes().then(() => {
        this.loopRoutesLoaded = true
        this.updateLoopRoutesFields()
      })
    }
    this.saveDraft()
  }

  // Mettre à jour les champs de parcours par boucle
  updateLoopRoutesFields() {
    const loopsCountInput = this.hasLoopsCountInputTarget ? this.loopsCountInputTarget : null
    const container = document.getElementById('loop-routes-container')
    const fieldsContainer = document.getElementById('loop-routes-fields')
    
    if (!loopsCountInput || !container || !fieldsContainer) return

    const loopsCount = parseInt(loopsCountInput.value) || 1
    
    // Afficher/masquer le container
    if (loopsCount > 1) {
      container.style.display = 'block'
    } else {
      container.style.display = 'none'
      return
    }

    // Générer les champs pour les boucles supplémentaires (à partir de la boucle 2)
    // La boucle 1 utilise le parcours principal du formulaire
    const routes = this.getRoutes() // Récupérer la liste des routes depuis le select
    let html = ''
    
    // Récupérer les parcours existants depuis le serveur si l'événement existe
    const eventId = this.getEventId()
    const existingLoopRoutes = eventId ? this.existingLoopRoutesData : {}
    
    // Commencer à partir de la boucle 2 (la boucle 1 utilise le parcours principal)
    for (let i = 2; i <= loopsCount; i++) {
      const existingLoopRoute = existingLoopRoutes[i] || this.getExistingLoopRoute(i)
      // Convertir en nombre pour la comparaison stricte
      const selectedRouteId = existingLoopRoute ? parseInt(existingLoopRoute.route_id) : null
      const distanceKm = existingLoopRoute ? existingLoopRoute.distance_km : ''
      
      html += `
        <div class="row g-3 mb-3 loop-route-row" data-loop-number="${i}">
          <div class="col-12">
            <h6 class="text-muted mb-2">
              <i class="bi bi-arrow-repeat me-1"></i>Boucle ${i}
            </h6>
          </div>
          <div class="col-md-6">
            <label class="form-label">Parcours</label>
            <select name="event_loop_routes[${i}][route_id]" 
                    class="form-select form-select-liquid loop-route-select"
                    data-loop-number="${i}"
                    data-action="change->event-form#loopRouteChanged">
              <option value="">Sans parcours</option>
              ${routes.map(route => {
                const routeId = parseInt(route.id)
                const isSelected = selectedRouteId && routeId === selectedRouteId
                return `
                <option value="${route.id}" ${isSelected ? 'selected' : ''}>
                  ${route.name}
                </option>
              `
              }).join('')}
            </select>
          </div>
          <div class="col-md-6">
            <label class="form-label">Distance (km)</label>
            <div class="input-group">
              <input type="number" 
                     name="event_loop_routes[${i}][distance_km]" 
                     class="form-control form-control-liquid loop-route-distance distance-input"
                     data-loop-number="${i}"
                     min="0" 
                     step="any" 
                     value="${distanceKm || ''}"
                     placeholder="Ex: 15.5"
                     data-action="input->event-form#loopRouteDistanceChanged keydown->event-form#handleDistanceKeydown">
              <span class="input-group-text">km</span>
            </div>
          </div>
        </div>
      `
    }
    
    fieldsContainer.innerHTML = html
    this.updateTotalDistance()
  }

  // Récupérer la liste des routes depuis le select principal
  getRoutes() {
    const routeSelect = this.hasRouteSelectTarget ? this.routeSelectTarget : null
    if (!routeSelect) return []
    
    const routes = []
    routeSelect.querySelectorAll('option').forEach(option => {
      if (option.value) {
        routes.push({
          id: parseInt(option.value),
          name: option.textContent.trim()
        })
      }
    })
    return routes
  }

  // Récupérer les parcours existants depuis les données du formulaire ou depuis les données chargées
  getExistingLoopRoute(loopNumber) {
    // Chercher dans les champs déjà générés
    const form = this.element.querySelector('form')
    if (!form) return null
    
    const existingSelect = form.querySelector(`select[name="event_loop_routes[${loopNumber}][route_id]"]`)
    const existingDistance = form.querySelector(`input[name="event_loop_routes[${loopNumber}][distance_km]"]`)
    
    if (existingSelect && existingSelect.value) {
      return {
        route_id: parseInt(existingSelect.value),
        distance_km: existingDistance ? existingDistance.value : ''
      }
    }
    
    return null
  }

  // Récupérer l'ID de l'événement depuis le formulaire
  getEventId() {
    const form = this.element.querySelector('form')
    if (!form) return null
    
    // Chercher un input caché avec l'ID
    const idInput = form.querySelector('input[name="event[id]"]')
    if (idInput && idInput.value) {
      return parseInt(idInput.value)
    }
    
    // Ou chercher dans l'action du formulaire
    const formAction = form.action
    const match = formAction.match(/\/events\/(\d+)/)
    if (match) {
      return parseInt(match[1])
    }
    
    return null
  }

  // Charger les parcours existants depuis le serveur
  async loadExistingLoopRoutes() {
    const eventId = this.getEventId()
    if (!eventId) {
      this.existingLoopRoutesData = {}
      return Promise.resolve()
    }
    
    try {
      const response = await fetch(`/events/${eventId}/loop_routes.json`)
      if (response.ok) {
        const data = await response.json()
        this.existingLoopRoutesData = {}
        // Ne charger que les boucles 2 et suivantes (la boucle 1 utilise le parcours principal)
        data.forEach(loopRoute => {
          if (loopRoute.loop_number > 1) {
            this.existingLoopRoutesData[loopRoute.loop_number] = {
              route_id: loopRoute.route_id,
              distance_km: loopRoute.distance_km
            }
          }
        })
        // Debug: afficher les données chargées
        console.log('Parcours par boucle chargés:', this.existingLoopRoutesData)
      } else {
        console.warn('Erreur lors du chargement des parcours par boucle:', response.status)
        this.existingLoopRoutesData = {}
      }
    } catch (error) {
      console.error('Erreur lors du chargement des parcours par boucle:', error)
      this.existingLoopRoutesData = {}
    }
    
    return Promise.resolve()
  }

  // Quand un parcours est sélectionné pour une boucle, pré-remplir la distance
  loopRouteChanged(event) {
    const select = event.target
    const loopNumber = parseInt(select.dataset.loopNumber)
    const routeId = select.value
    
    if (!routeId) return
    
    // Charger les infos du parcours
    fetch(`/routes/${routeId}/info`)
      .then(response => {
        if (!response.ok) throw new Error('Erreur lors du chargement du parcours')
        return response.json()
      })
      .then(data => {
        const distanceInput = this.element.querySelector(`input[name="event_loop_routes[${loopNumber}][distance_km]"]`)
        if (distanceInput && data.distance_km) {
          distanceInput.value = data.distance_km
        }
        this.updateTotalDistance()
        this.saveDraft()
      })
      .catch(error => {
        console.error('Erreur:', error)
      })
  }

  // Mettre à jour la distance totale quand la distance d'une boucle change
  loopRouteDistanceChanged() {
    this.updateTotalDistance()
    this.saveDraft()
  }

  distanceChanged() {
    this.updateTotalDistance()
    this.saveDraft()
  }

  // Gérer les flèches pour incrémenter/décrémenter de 0.5
  handleDistanceKeydown(event) {
    // Vérifier si c'est une flèche haut ou bas
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      const input = event.target
      const currentValue = parseFloat(input.value) || 0
      const step = 0.5
      
      // Empêcher le comportement par défaut
      event.preventDefault()
      
      // Calculer la nouvelle valeur
      let newValue
      if (event.key === 'ArrowUp') {
        newValue = currentValue + step
      } else {
        newValue = Math.max(0, currentValue - step) // Ne pas aller en dessous de 0
      }
      
      // Mettre à jour la valeur
      input.value = newValue.toFixed(1)
      
      // Déclencher l'événement input pour mettre à jour la distance totale
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  updateTotalDistance() {
    const distanceInput = this.hasDistanceInputTarget ? this.distanceInputTarget : null
    const loopsInput = this.hasLoopsCountInputTarget ? this.loopsCountInputTarget : null
    const totalDisplay = document.getElementById('total-distance-display')
    const totalValue = document.getElementById('total-distance-value')

    if (!loopsInput || !totalDisplay || !totalValue) return

    const loops = parseInt(loopsInput.value) || 1
    
    // Calculer la distance totale selon le système utilisé
    let total = 0
    
    if (loops > 1) {
      // Nouveau système : distance boucle 1 (champ principal) + distances boucles supplémentaires
      const distanceBoucle1 = distanceInput ? (parseFloat(distanceInput.value) || 0) : 0
      total = distanceBoucle1
      
      // Ajouter les distances des boucles supplémentaires (2, 3, etc.)
      const loopDistanceInputs = this.element.querySelectorAll('.loop-route-distance')
      loopDistanceInputs.forEach(input => {
        const distance = parseFloat(input.value) || 0
        total += distance
      })
    } else {
      // Une seule boucle
      const distance = distanceInput ? (parseFloat(distanceInput.value) || 0) : 0
      total = distance
    }

    if (loops > 1 && total > 0) {
      totalValue.textContent = total.toFixed(1)
      totalDisplay.style.display = 'block'
    } else {
      totalDisplay.style.display = 'none'
    }
  }

  // ========================================
  // SAUVEGARDE AUTOMATIQUE (RGPD COMPLIANT)
  // ========================================

  // Vérifier si l'utilisateur a accepté les cookies de préférences
  hasCookieConsent() {
    try {
      const consentCookie = this.getCookie('cookie_consent')
      if (!consentCookie) return false
      
      const consentData = JSON.parse(consentCookie)
      return consentData.preferences === true
    } catch (e) {
      return false
    }
  }

  // Obtenir un cookie par nom
  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(';').shift()
    return null
  }

  // Sauvegarder les données du formulaire
  saveDraft() {
    const formData = this.collectFormData()
    if (Object.keys(formData).length === 0) return

    const draftData = {
      data: formData,
      timestamp: new Date().toISOString(),
      expiresAt: new Date(Date.now() + this.storageExpiryDays * 24 * 60 * 60 * 1000).toISOString()
    }

    try {
      if (this.hasCookieConsent()) {
        // Utiliser les cookies si consentement donné
        this.setCookie(this.storageKey, JSON.stringify(draftData), this.storageExpiryDays)
      } else {
        // Sinon utiliser localStorage (stockage local uniquement)
        localStorage.setItem(this.storageKey, JSON.stringify(draftData))
      }
      
      // Afficher un indicateur discret de sauvegarde
      this.showSaveIndicator()
    } catch (e) {
      console.warn('Impossible de sauvegarder le brouillon:', e)
    }
  }

  // Collecter toutes les données du formulaire
  collectFormData() {
    const form = this.element.querySelector('form')
    if (!form) return {}

    const formData = {}
    const inputs = form.querySelectorAll('input, select, textarea')
    
    inputs.forEach(input => {
      // Ignorer les champs cachés système (CSRF, etc.)
      if (input.type === 'hidden' && (input.name === 'authenticity_token' || input.name === 'utf8')) {
        return
      }
      
      // Ignorer les fichiers (ne peuvent pas être sauvegardés)
      if (input.type === 'file') {
        return
      }

      const name = input.name
      if (name) {
        if (input.type === 'checkbox') {
          formData[name] = input.checked
        } else {
          formData[name] = input.value
        }
      }
    })

    return formData
  }

  // Restaurer les données sauvegardées
  restoreDraft() {
    let draftData = null

    try {
      if (this.hasCookieConsent()) {
        // Récupérer depuis les cookies
        const cookieData = this.getCookie(this.storageKey)
        if (cookieData) {
          draftData = JSON.parse(cookieData)
        }
      } else {
        // Récupérer depuis localStorage
        const localData = localStorage.getItem(this.storageKey)
        if (localData) {
          draftData = JSON.parse(localData)
        }
      }

      if (!draftData) return

      // Vérifier l'expiration
      const expiresAt = new Date(draftData.expiresAt)
      if (expiresAt < new Date()) {
        this.clearDraft()
        return
      }

      // Restaurer les champs (uniquement si le formulaire est vide)
      if (this.isFormEmpty()) {
        this.fillFormData(draftData.data)
        this.showRestoreMessage()
      }
    } catch (e) {
      console.warn('Impossible de restaurer le brouillon:', e)
      this.clearDraft()
    }
  }

  // Vérifier si le formulaire est vide
  isFormEmpty() {
    const form = this.element.querySelector('form')
    if (!form) return true

    const inputs = form.querySelectorAll('input[type="text"], input[type="number"], input[type="datetime-local"], textarea, select')
    for (const input of inputs) {
      if (input.name && input.value && input.name !== 'authenticity_token' && input.name !== 'utf8') {
        return false
      }
    }
    return true
  }

  // Remplir le formulaire avec les données sauvegardées
  fillFormData(data) {
    const form = this.element.querySelector('form')
    if (!form) return

    Object.keys(data).forEach(name => {
      const input = form.querySelector(`[name="${name}"]`)
      if (input) {
        if (input.type === 'checkbox') {
          input.checked = data[name] === true || data[name] === 'true'
        } else {
          input.value = data[name]
          // Déclencher les événements pour les champs avec listeners
          input.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }
    })
  }

  // Configurer la sauvegarde automatique
  setupAutoSave() {
    const form = this.element.querySelector('form')
    if (!form) return

    // Sauvegarder lors des modifications (debounce pour éviter trop de sauvegardes)
    let saveTimeout
    form.addEventListener('input', () => {
      clearTimeout(saveTimeout)
      saveTimeout = setTimeout(() => {
        this.saveDraft()
      }, 1000) // Sauvegarder 1 seconde après la dernière modification
    })

    form.addEventListener('change', () => {
      clearTimeout(saveTimeout)
      saveTimeout = setTimeout(() => {
        this.saveDraft()
      }, 500)
    })
  }

  // Configurer le nettoyage après soumission
  setupCleanup() {
    const form = this.element.querySelector('form')
    if (!form) return

    form.addEventListener('submit', () => {
      // Nettoyer immédiatement après soumission
      setTimeout(() => {
        this.clearDraft()
      }, 100)
    })
  }

  // Nettoyer les données sauvegardées
  clearDraft() {
    try {
      if (this.hasCookieConsent()) {
        this.deleteCookie(this.storageKey)
      } else {
        localStorage.removeItem(this.storageKey)
      }
    } catch (e) {
      console.warn('Impossible de nettoyer le brouillon:', e)
    }
  }

  // Définir un cookie
  setCookie(name, value, days) {
    const expires = new Date()
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`
  }

  // Supprimer un cookie
  deleteCookie(name) {
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;`
  }

  // Afficher un indicateur discret de sauvegarde
  showSaveIndicator() {
    // Créer ou mettre à jour un indicateur discret
    let indicator = document.getElementById('draft-save-indicator')
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'draft-save-indicator'
      indicator.className = 'position-fixed bottom-0 end-0 m-3'
      indicator.style.cssText = 'z-index: 1040; font-size: 0.75rem; color: var(--bs-success);'
      document.body.appendChild(indicator)
    }
    
    indicator.innerHTML = '<i class="bi bi-check-circle me-1"></i>Brouillon sauvegardé'
    indicator.style.opacity = '1'
    
    // Faire disparaître après 2 secondes
    setTimeout(() => {
      indicator.style.transition = 'opacity 0.5s'
      indicator.style.opacity = '0'
    }, 2000)
  }

  // Afficher un message de restauration
  showRestoreMessage() {
    const form = this.element.querySelector('form')
    if (!form) return

    // Créer un message informatif en haut du formulaire
    const alertDiv = document.createElement('div')
    alertDiv.className = 'alert alert-info alert-dismissible fade show mb-3'
    alertDiv.innerHTML = `
      <i class="bi bi-info-circle me-2"></i>
      <strong>Brouillon restauré</strong> : Vos données précédemment saisies ont été restaurées.
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fermer"></button>
    `
    
    const firstChild = form.firstElementChild
    if (firstChild) {
      form.insertBefore(alertDiv, firstChild)
    } else {
      form.appendChild(alertDiv)
    }

    // Auto-fermer après 5 secondes
    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.classList.remove('show')
        setTimeout(() => alertDiv.remove(), 300)
      }
    }, 5000)
  }

  // Gérer la création de parcours depuis la modal
  setupRouteCreation() {
    const createRouteForm = document.getElementById('createRouteForm')
    if (!createRouteForm) return

    createRouteForm.addEventListener('submit', (e) => {
      e.preventDefault()
      
      const submitBtn = document.getElementById('createRouteSubmit')
      const errorsDiv = document.getElementById('createRouteErrors')
      const formData = new FormData(createRouteForm)
      
      // S'assurer que le format est correct pour Rails (route[...])
      // Rails form_with génère automatiquement route[name], route[distance_km], etc.
      // Mais FormData les envoie directement, donc on doit les wrapper
      const wrappedFormData = new FormData()
      for (const [key, value] of formData.entries()) {
        wrappedFormData.append(`route[${key}]`, value)
      }
      
      // Désactiver le bouton pendant la requête
      submitBtn.disabled = true
      submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Création...'
      errorsDiv.style.display = 'none'
      
      fetch('/routes.json', {
        method: 'POST',
        body: wrappedFormData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.id) {
          // Parcours créé avec succès
          // Ajouter au select et sélectionner
          const routeSelect = this.hasRouteSelectTarget ? this.routeSelectTarget : null
          if (routeSelect) {
            const option = document.createElement('option')
            option.value = data.id
            option.textContent = data.name
            option.selected = true
            routeSelect.appendChild(option)
            
            // Déclencher le changement pour pré-remplir les champs
            routeSelect.dispatchEvent(new Event('change', { bubbles: true }))
          }
          
          // Fermer la modal
          const modal = bootstrap.Modal.getInstance(document.getElementById('createRouteModal'))
          if (modal) modal.hide()
          
          // Réinitialiser le formulaire
          createRouteForm.reset()
        } else if (data.errors) {
          // Afficher les erreurs
          errorsDiv.innerHTML = '<strong>Erreurs :</strong><ul class="mb-0 mt-2"><li>' + 
            data.errors.join('</li><li>') + '</li></ul>'
          errorsDiv.style.display = 'block'
        }
      })
      .catch(error => {
        console.error('Erreur lors de la création du parcours:', error)
        errorsDiv.innerHTML = '<strong>Erreur :</strong> Impossible de créer le parcours. Veuillez réessayer.'
        errorsDiv.style.display = 'block'
      })
      .finally(() => {
        submitBtn.disabled = false
        submitBtn.innerHTML = 'Créer le parcours'
      })
    })
  }
}
