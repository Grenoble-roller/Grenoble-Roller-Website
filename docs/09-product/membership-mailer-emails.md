---
title: "Emails Adhésions (MembershipMailer) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["membership", "emails", "mailer", "adhésions"]
---

# Emails Adhésions (MembershipMailer)

**Dernière mise à jour** : 2025-01-30

Ce document décrit les 4 emails envoyés pour les adhésions : activation, expiration, rappel de renouvellement, et échec de paiement.

---

## 📋 Vue d'Ensemble

Le `MembershipMailer` envoie des emails automatiques pour gérer le cycle de vie des adhésions (activations, expirations, rappels, échecs de paiement).

### Emails Disponibles

1. **`activated`** : Adhésion activée (paiement confirmé)
2. **`expired`** : Adhésion expirée
3. **`renewal_reminder`** : Rappel renouvellement (30 jours avant expiration)
4. **`payment_failed`** : Échec de paiement

---

## 📧 Email 1 : Adhésion Activée (`activated`)

### Méthode

```ruby
def activated(membership)
  @membership = membership
  @user = membership.user
  mail(to: @user.email, subject: "✅ Adhésion Saison #{@membership.season} - Bienvenue !")
end
```

### Déclenchement

**Quand** : Quand une adhésion est activée (paiement confirmé)

**Probablement appelé dans** :
- `MembershipsController#pay` (après confirmation paiement HelloAsso)
- `HelloassoService` (polling automatique, détection paiement confirmé)

**Logique** :
- Statut adhésion passe de `pending` à `active`
- Paiement HelloAsso confirmé
- Dates calculées (start_date, end_date)

### Templates

- **HTML** : `app/views/membership_mailer/activated.html.erb`
- **Text** : `app/views/membership_mailer/activated.text.erb`

### Contenu (Typique)

- Message de bienvenue
- Confirmation d'adhésion
- Saison concernée
- Dates d'adhésion (start_date → end_date)
- Type d'adhésion (FFRS, Association, Adulte, Enfant)
- Informations utiles (prochaines initiations, événements)

### Variables Disponibles

- `@membership` : Objet Membership (avec toutes les méthodes)
- `@user` : Utilisateur propriétaire de l'adhésion
- `@membership.season` : Saison (ex: "2024-2025")
- `@membership.start_date` : Date de début
- `@membership.end_date` : Date de fin
- `@membership.membership_type` : Type (FFRS, Association)
- `@membership.is_child_membership` : Adulte ou enfant

---

## 📧 Email 2 : Adhésion Expirée (`expired`)

### Méthode

```ruby
def expired(membership)
  @membership = membership
  @user = membership.user
  mail(to: @user.email, subject: "⏰ Adhésion Saison #{@membership.season} - Expirée")
end
```

### Déclenchement

**Quand** : Quand une adhésion expire (après `end_date`)

**Probablement appelé dans** :
- **Job cron** : Vérification quotidienne des adhésions expirées
- **Callback modèle** : Après `end_date` (si configuré)

**Logique** :
- Statut adhésion passe de `active` à `expired`
- `end_date` dépassé
- Notification envoyée automatiquement

### Templates

- **HTML** : `app/views/membership_mailer/expired.html.erb`
- **Text** : `app/views/membership_mailer/expired.text.erb`

### Contenu (Typique)

- Notification d'expiration
- Date d'expiration
- Saison concernée
- Lien pour renouveler
- Informations sur le renouvellement
- Impact de l'expiration (accès initiations, etc.)

### Variables Disponibles

- `@membership` : Objet Membership
- `@user` : Utilisateur
- `@membership.season` : Saison
- `@membership.end_date` : Date d'expiration

---

## 📧 Email 3 : Rappel Renouvellement (`renewal_reminder`)

### Méthode

```ruby
def renewal_reminder(membership)
  @membership = membership
  @user = membership.user
  mail(to: @user.email, subject: "🔄 Renouvellement d'adhésion - Dans 30 jours")
end
```

### Déclenchement

**Quand** : 30 jours avant l'expiration (`end_date - 30 days`)

**Probablement appelé dans** :
- **Job cron** : Vérification quotidienne des adhésions à expirer dans 30 jours
- **Scheduled job** : Exécuté chaque jour, vérifie les adhésions actives

**Logique** :
- Adhésion `active`
- `end_date` dans 30 jours (± 1 jour)
- Pas déjà envoyé (nécessite un flag ou vérification)

### Templates

- **HTML** : `app/views/membership_mailer/renewal_reminder.html.erb`
- **Text** : `app/views/membership_mailer/renewal_reminder.text.erb`

### Contenu (Typique)

- Rappel de renouvellement
- Date d'expiration dans 30 jours
- Lien direct pour renouveler
- Instructions pour le renouvellement
- Avantages du renouvellement

### Variables Disponibles

- `@membership` : Objet Membership
- `@user` : Utilisateur
- `@membership.season` : Saison actuelle
- `@membership.end_date` : Date d'expiration
- `@days_until_expiry` : Jours restants (30)

---

## 📧 Email 4 : Échec Paiement (`payment_failed`)

### Méthode

```ruby
def payment_failed(membership)
  @membership = membership
  @user = membership.user
  mail(to: @user.email, subject: "❌ Paiement adhésion Saison #{@membership.season} - Échec")
end
```

### Déclenchement

**Quand** : Quand un paiement HelloAsso échoue

**Probablement appelé dans** :
- `HelloassoService` : Détection échec de paiement (polling)
- `MembershipsController` : Après tentative de paiement échouée
- Webhook HelloAsso (si configuré)

**Logique** :
- Paiement HelloAsso avec statut `failed` ou `cancelled`
- Adhésion reste en `pending`
- Notification envoyée à l'utilisateur

### Templates

- **HTML** : `app/views/membership_mailer/payment_failed.html.erb`
- **Text** : `app/views/membership_mailer/payment_failed.text.erb`

### Contenu (Typique)

- Notification d'échec de paiement
- Saison concernée
- Raison de l'échec (si disponible)
- Instructions pour réessayer
- Lien pour renouveler la tentative de paiement
- Support contact

### Variables Disponibles

- `@membership` : Objet Membership
- `@user` : Utilisateur
- `@membership.season` : Saison
- `@payment` : Objet Payment (si disponible, avec raison échec)

---

## 🔄 Cycle de Vie d'une Adhésion

```
1. Création (pending)
   ↓
2. Tentative paiement
   ↓
   ├─→ Succès → activated ✅
   │           ↓
   │     3. Actif (active)
   │           ↓
   │     4. 30 jours avant expiration → renewal_reminder 📧
   │           ↓
   │     5. Expiration → expired 📧
   │
   └─→ Échec → payment_failed ❌
                (peut réessayer)
```

---

## 🎯 Configuration et Déclenchement

### Jobs Cron (Probablement)

**Fichier** : `config/schedule.rb` (Whenever) ou `app/jobs/`

**Jobs nécessaires** :
1. **CheckExpiredMembershipsJob** : Vérifie quotidiennement les adhésions expirées
2. **RenewalReminderJob** : Vérifie quotidiennement les adhésions à expirer dans 30 jours

**Exemple** :
```ruby
# Tous les jours à 9h
every 1.day, at: '9:00 am' do
  runner "RenewalReminderJob.perform_later"
  runner "CheckExpiredMembershipsJob.perform_later"
end
```

### Callbacks Modèle (Alternative)

**Dans `Membership` model** :
```ruby
after_update :send_expired_email, if: :saved_change_to_status?
after_update :send_renewal_reminder, if: :should_send_renewal_reminder?

def send_expired_email
  MembershipMailer.expired(self).deliver_later if expired?
end
```

**Note** : Nécessite un flag pour éviter les envois multiples.

---

## 📝 Bonnes Pratiques

### Éviter les Doublons

**Problème** : Envoyer plusieurs fois le même email

**Solutions** :
- Flag `renewal_reminder_sent_at` dans `memberships` table
- Vérification avant envoi
- Logging des envois

### Gestion des Erreurs

**Problème** : Échec d'envoi d'email

**Solutions** :
- Utiliser `deliver_later` (ActiveJob)
- Retry automatique (config ActiveJob)
- Logging des erreurs
- Notification admin si échec répété

### Performance

**Problème** : Vérifier toutes les adhésions quotidiennement

**Solutions** :
- Scopes optimisés (`active`, `expiring_soon`)
- Batch processing (find_each)
- Index sur `status`, `end_date`

---

## 🔗 Références

- **Mailer** : `app/mailers/membership_mailer.rb`
- **Templates HTML** : `app/views/membership_mailer/*.html.erb`
- **Templates Text** : `app/views/membership_mailer/*.text.erb`
- **Modèle Membership** : `app/models/membership.rb`
- **Service HelloAsso** : `app/services/helloasso_service.rb`
- **Contrôleur** : `app/controllers/memberships_controller.rb`

---

## 🎯 Améliorations Futures Possibles

1. **Flags de suivi** : Ajouter `renewal_reminder_sent_at`, `expired_email_sent_at` dans `memberships`
2. **Jobs dédiés** : Créer `RenewalReminderJob` et `CheckExpiredMembershipsJob`
3. **Personnalisation** : Templates différents selon type d'adhésion (adulte/enfant, FFRS/Association)
4. **Multi-rappels** : Rappel à 30 jours, 7 jours, 1 jour avant expiration
5. **Statistiques** : Suivi des ouvertures/clics (si service email tracking)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

