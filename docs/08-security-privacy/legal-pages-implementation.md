---
title: "Implémentation Pages Légales & Gestion Cookies"
status: "active"
version: "1.0"
created: "2025-11-21"
updated: "2026-08-14"
tags: ["legal", "rgpd", "cookies", "compliance", "stimulus"]
---

# Implémentation Pages Légales & Gestion Cookies

**Date de création** : 2025-11-21  
**Branche** : `feature/legal-pages`  
**Status** : ✅ Terminé et conforme

---

## 📋 Vue d'Ensemble

Implémentation complète des pages légales obligatoires et d'un système de gestion des cookies conforme aux standards RGPD 2025 et directive ePrivacy.

### Pages Légales Créées

1. ✅ **Mentions Légales** (`/mentions-legales`)
   - Obligatoire (risque : 75 000€)
   - Informations éditeur, hébergeur, activité commerciale
   - Conforme LCEN (loi pour la confiance en l'économie numérique)

2. ✅ **Politique de Confidentialité / RGPD** (`/politique-confidentialite`, `/rgpd`)
   - Obligatoire (risque : 4% CA ou 20M€)
   - Données collectées, finalités, droits utilisateurs, cookies
   - Conforme RGPD

3. ✅ **Conditions Générales de Vente** (`/cgv`, `/conditions-generales-vente`)
   - Obligatoire (risque : 15 000€)
   - Modalités paiement, livraison/récupération, droit de rétractation (exception L221-28)
   - Conforme Code de la consommation

4. ✅ **Conditions Générales d'Utilisation** (`/cgu`, `/conditions-generales-utilisation`)
   - Recommandé
   - Règles d'utilisation du site, droits et obligations

5. ✅ **Contact** (`/contact`)
   - Recommandé
   - Coordonnées email uniquement (pas de formulaire, comme demandé)

---

## 🍪 Système de Gestion des Cookies

### Architecture

- **Contrôleur Stimulus** : `app/javascript/controllers/cookie_consent_controller.js`
- **Contrôleur Rails** : `app/controllers/cookie_consents_controller.rb`
- **Helper Ruby** : `app/helpers/cookie_consent_helper.rb`
- **Banner** : `app/views/layouts/_cookie_banner.html.erb`
- **Page préférences** : `app/views/cookie_consents/preferences.html.erb`

### Routes RESTful

```ruby
resource :cookie_consent, only: [] do
  collection do
    get :preferences
    post :accept
    post :reject
    patch :update
  end
end
```

**Routes générées** :
- `GET /cookie_consent/preferences` → `preferences_cookie_consent_path`
- `POST /cookie_consent/accept` → `accept_cookie_consent_path`
- `POST /cookie_consent/reject` → `reject_cookie_consent_path`
- `PATCH /cookie_consent` → `cookie_consent_path`

### Types de Cookies

1. **Cookies strictement nécessaires** (toujours actifs)
   - Cookies de session Rails (`_session_id`)
   - Authentification Devise
   - Panier d'achat (`session[:cart]`)
   - Pas de consentement requis (RGPD)

2. **Cookies de préférence** (consentement requis)
   - Cookie "Remember me" (Devise)
   - Préférences utilisateur

3. **Cookies analytiques** (consentement requis)
   - **[Umami](umami-analytics.md)** (mesure d'audience, self-hosted) — chargé uniquement si consentement `analytics` + variables `UMAMI_SCRIPT_URL` / `UMAMI_WEBSITE_ID`

### Configuration des Cookies

- **Durée** : 13 mois (conforme RGPD)
- **Sécurité** : `SameSite: Lax`, `Secure` en production
- **Stockage** : Cookie permanent avec timestamp du consentement
- **Format** : JSON structuré

---

## 🏗️ Architecture Technique

### Contrôleur Stimulus

```javascript
// app/javascript/controllers/cookie_consent_controller.js
- Targets: banner, acceptButton, rejectButton
- Values: acceptUrl, rejectUrl
- Actions: accept(), reject()
- Lifecycle: connect() pour initialisation
```

**Fonctionnalités** :
- Détection automatique du consentement
- Affichage/masquage du banner
- Envoi des préférences via fetch API
- Compatibilité Turbo
- Gestion d'erreurs robuste

### Contrôleur Rails

```ruby
# app/controllers/cookie_consents_controller.rb
- Actions: preferences, accept, reject, update
- Pas d'authentification requise
- Réponses JSON et HTML
- Configuration cookies conforme RGPD 2025
```

### Helper Ruby

```ruby
# app/helpers/cookie_consent_helper.rb
- cookie_consent?(type) : Vérifier consentement par type
- has_cookie_consent? : Vérifier si consentement existe
- cookie_preferences : Obtenir toutes les préférences
```

---

## 📍 Intégration

### Footer

- **Footer simple** (actuel) : Tous les liens légaux présents
- **Footer complet** : Mis à jour avec liens légaux (prêt pour utilisation future)

### Layout Principal

- Banner de cookies intégré dans `application.html.erb`
- Affichage automatique si pas de consentement
- Compatible avec Turbo et Stimulus

---

## ✅ Conformité

### RGPD
- ✅ Politique de confidentialité complète
- ✅ Gestion des cookies conforme
- ✅ Droits des utilisateurs documentés
- ✅ Durée de conservation spécifiée
- ✅ Contact CNIL mentionné

### Directive ePrivacy
- ✅ Banner de consentement avant activation
- ✅ Possibilité de refuser les cookies non essentiels
- ✅ Préférences détaillées disponibles
- ✅ Possibilité de modifier le consentement

### Code de la Consommation
- ✅ CGV complètes avec toutes les informations obligatoires
- ✅ Exception légale L221-28 documentée (pas de droit de rétractation pour articles personnalisés)
- ✅ Garanties légales mentionnées

### Loi pour la Confiance en l'Économie Numérique
- ✅ Mentions légales complètes
- ✅ Informations éditeur et hébergeur
- ✅ Directeur de publication identifié

---

## 🔗 Liens Utiles

- **Guide complet** : [`legal-pages-guide.md`](legal-pages-guide.md)
- **Informations collectées** : [`informations-a-collecter.md`](informations-a-collecter.md)
- **Routes** : [`../04-rails/routes.md`](../04-rails/routes.md)
- **Changelog** : [`../10-decisions-and-changelog/CHANGELOG.md`](../10-decisions-and-changelog/CHANGELOG.md)

---

## 📝 Notes Importantes

### Cookies de Session Rails

Les cookies de session Rails sont **strictement nécessaires** et ne nécessitent pas de consentement selon le RGPD. Ils sont utilisés pour :
- Authentification (Devise)
- Panier d'achat (`session[:cart]`)
- Sécurité CSRF

Ces cookies sont **toujours actifs** et ne peuvent pas être désactivés.

### Maintenance

- Les pages légales doivent être mises à jour en cas de changement (nouveau président, changement d'adresse, etc.)
- Les préférences de cookies sont stockées pendant 13 mois maximum
- Le système est prêt pour l'ajout de cookies analytiques si nécessaire

---

**Dernière mise à jour** : 2026-08-14

