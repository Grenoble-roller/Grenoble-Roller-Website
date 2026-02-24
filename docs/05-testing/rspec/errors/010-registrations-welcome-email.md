# Erreur #010 : Registrations – welcome email (deliver_now vs deliver_later)

**Date d'analyse** : 2026-02-24  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Requests – registrations

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/registrations_spec.rb`
- **Ligne** : 70
- **Test** : `POST /users with valid parameters and RGPD consent sends welcome email`
- **Commande pour reproduire** :
  ```bash
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/registrations_spec.rb:70
  ```

---

## 🔴 Erreur

`expected to enqueue exactly 1 jobs, with ["UserMailer", "welcome_email", "deliver_later", ...], but enqueued 0`. Queued jobs: `... "deliver_now" ...`. Le spec attend `deliver_later`, l’app envoie en `deliver_now` (ou le matcher ne voit pas le job).

---

## 🔍 Analyse

- Soit l’app envoie le mail en `deliver_now` au lieu de `deliver_later`, et le spec est correct → adapter l’app.
- Soit l’app fait bien `deliver_later` mais le matcher (have_enqueued_job avec "deliver_later") ne matche pas (queue adapter test, ou signature du job).

---

## 💡 Solutions Proposées

1. **App** : S’assurer que l’inscription utilise `UserMailer.welcome_email(...).deliver_later` (ou équivalent).
2. **Test** : Si l’app utilise volontairement `deliver_now`, adapter le spec pour vérifier l’envoi (ex. expect ... to have_enqueued_job avec "deliver_now", ou ne pas vérifier la queue et vérifier autrement l’envoi).

---

## 🎯 Type de Problème

Souvent ❌ **PROBLÈME DE TEST** (matcher) ou ⚠️ **PROBLÈME DE LOGIQUE** (deliver_now vs deliver_later).

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

- Audit catégorie 3 (Registrations – redirect, jobs).
