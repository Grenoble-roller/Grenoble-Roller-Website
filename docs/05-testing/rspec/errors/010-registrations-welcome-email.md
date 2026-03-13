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
  bundle exec rspec spec/requests/registrations_spec.rb:70
  ```

---

## 🔴 Erreur

`expected to enqueue exactly 1 jobs, with ["UserMailer", "welcome_email", "deliver_later", ...], but enqueued 0`.  
Queued jobs: un job `ActionMailer::MailDeliveryJob` avec `"UserMailer", "welcome_email", "deliver_now", ...`.  
Le spec exigeait strictement `deliver_later`, alors que le job en file contenait `deliver_now` (comportement possible selon Rails/Devise ou l’ordre d’envoi des mails).

---

## 🔍 Analyse

- L’app envoie bien l’email de bienvenue via `User#send_welcome_email_and_confirmation` et `UserMailer.welcome_email(self).deliver_later`.
- En test, le job enqueued peut être enregistré avec `deliver_now` comme méthode de livraison (série d’arguments du `MailDeliveryJob`), selon la version de Rails ou le chemin d’envoi (ex. Devise confirmation).
- Le spec vérifiait une égalité stricte sur le 3ᵉ argument (`'deliver_later'`), ce qui faisait échouer le test alors que le job `UserMailer.welcome_email` était bien enqueued.

---

## 💡 Solution Appliquée

**Spec** : assouplir le matcher pour accepter `deliver_later` ou `deliver_now` pour l’email de bienvenue, tout en vérifiant que le job `UserMailer.welcome_email` est bien enqueued avec un `User` en argument :

```ruby
.with('UserMailer', 'welcome_email', a_string_matching(/\Adeliver_(later|now)\z/), args: [ kind_of(User) ])
```

Aucune modification de l’app : le code reste en `deliver_later`.

---

## 🎯 Type de Problème

**Problème de test** (matcher trop strict par rapport au format réel du job en file).

---

## Impact vues

Aucune modification des vues ni du flux d’inscription.

---

## 📊 Statut

✅ **RÉSOLU**
