# ⚡ JAVASCRIPT - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

JavaScript pour les initiations. Pour le MVP, aucun JavaScript spécifique n'est nécessaire, les formulaires fonctionnent avec Turbo (Hotwire).

---

## ✅ JavaScript Optionnel (Phase 2)

Pour améliorer l'UX dans une phase ultérieure, on pourra ajouter :

### **1. Controller Stimulus : PresencesController**

**Fichier** : `app/javascript/controllers/admin_panel/presences_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "saveButton"]
  
  connect() {
    // Auto-save après changement de statut (debounce)
    this.timeout = null
  }
  
  change() {
    // Débounce pour éviter trop de requêtes
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.saveButtonTarget.classList.add("btn-warning")
      this.saveButtonTarget.textContent = "Sauvegarder (modifications non sauvegardées)"
    }, 500)
  }
  
  submit(event) {
    // Feedback visuel lors de la soumission
    this.saveButtonTarget.disabled = true
    this.saveButtonTarget.textContent = "Sauvegarde en cours..."
  }
}
```

**Utilisation dans la vue** :
```erb
<%= form_with url: update_presences_admin_panel_initiation_path(@initiation), 
    method: :patch, 
    local: true,
    data: { controller: "admin-panel--presences", 
            action: "turbo:submit-end->admin-panel--presences#submit" } do |f| %>
  <!-- ... -->
  <%= f.submit "Sauvegarder présences", 
      class: "btn btn-primary btn-lg",
      data: { "admin-panel--presences-target": "saveButton" } %>
<% end %>
```

---

### **2. Confirmation avant actions critiques**

**Fichier** : `app/javascript/controllers/admin_panel/confirm_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }
  
  connect() {
    this.element.addEventListener("click", this.confirm.bind(this))
  }
  
  confirm(event) {
    if (!confirm(this.messageValue || "Êtes-vous sûr ?")) {
      event.preventDefault()
    }
  }
}
```

**Utilisation** :
```erb
<%= button_to "Convertir", convert_waitlist_admin_panel_initiation_path(@initiation, waitlist_entry_id: entry.hashid),
    method: :post, 
    class: "btn btn-outline-success",
    data: { controller: "admin-panel--confirm",
            "admin-panel--confirm-message-value": "Convertir cette entrée en inscription ?" } %>
```

---

### **3. Auto-refresh pour liste d'attente**

**Fichier** : `app/javascript/controllers/admin_panel/auto_refresh_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: Number }
  
  connect() {
    this.interval = this.intervalValue || 30000 // 30 secondes par défaut
    this.start()
  }
  
  disconnect() {
    this.stop()
  }
  
  start() {
    this.timer = setInterval(() => {
      Turbo.visit(window.location.href, { action: "replace" })
    }, this.interval)
  }
  
  stop() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }
}
```

**Utilisation** :
```erb
<div data-controller="admin-panel--auto-refresh" 
     data-admin-panel--auto-refresh-interval-value="30000">
  <!-- Contenu à rafraîchir -->
</div>
```

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Vérifier JavaScript nécessaire → Aucun JavaScript nécessaire pour MVP
- [ ] JavaScript Phase 2 (optionnel, amélioration UX)

---

## 📝 Notes

- **MVP** : Les formulaires fonctionnent avec Turbo (Hotwire) natif, pas besoin de JavaScript supplémentaire
- **Phase 2** : Ajouter des améliorations UX (auto-save, confirmations, auto-refresh) si nécessaire
- **Stimulus** : Utiliser Stimulus pour toute interactivité JavaScript (déjà dans le projet)

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
