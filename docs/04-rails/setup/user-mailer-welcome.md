---
title: "Email de Bienvenue (UserMailer.welcome_email) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["mailer", "user", "welcome", "onboarding"]
---

# Email de Bienvenue (UserMailer.welcome_email)

**Dernière mise à jour** : 2025-01-30

Ce document décrit l'email de bienvenue envoyé automatiquement aux nouveaux utilisateurs lors de leur inscription.

---

## 📋 Vue d'Ensemble

L'email de bienvenue est envoyé automatiquement à chaque nouveau compte utilisateur créé, pour les accueillir sur la plateforme et les guider dans leurs premiers pas.

### Fonctionnalités

- ✅ Envoi automatique après inscription
- ✅ Template HTML responsive
- ✅ Version texte alternative
- ✅ Envoi asynchrone (ActiveJob)
- ✅ Lien vers les événements

---

## 📧 Mailer : `UserMailer.welcome_email`

**Fichier** : `app/mailers/user_mailer.rb`

### Méthode

```ruby
def welcome_email(user)
  @user = user
  @events_url = events_url

  mail(
    to: @user.email,
    subject: "🎉 Bienvenue chez Grenoble Roller!"
  )
end
```

### Paramètres

- `user` : Objet User (utilisateur nouvellement créé)

### Variables d'Instance

- `@user` : Utilisateur destinataire
- `@events_url` : URL vers la liste des événements (helper `events_url`)

### Sujet

```
🎉 Bienvenue chez Grenoble Roller!
```

---

## 🔄 Déclenchement Automatique

### Callback dans User Model

**Fichier** : `app/models/user.rb`

```ruby
after_create :send_welcome_email_and_confirmation

private

def send_welcome_email_and_confirmation
  # Envoie l'email de confirmation Devise
  send_confirmation_instructions
  
  # Envoie l'email de bienvenue
  UserMailer.welcome_email(self).deliver_later
end
```

### Logique

**Moment** : Après création réussie du compte (`after_create`)

**Actions** :
1. Envoie les instructions de confirmation Devise (`send_confirmation_instructions`)
2. Envoie l'email de bienvenue (`UserMailer.welcome_email`)

**Méthode** : `deliver_later` (asynchrone via ActiveJob)

### Désactivation pour Seeds

**Dans `db/seeds.rb` et `db/seeds_production.rb`** :

```ruby
# Désactiver temporairement pour éviter envoi d'emails lors du seed
User.skip_callback(:create, :after, :send_welcome_email_and_confirmation)

# ... création des utilisateurs ...

# Réactiver après le seed
User.set_callback(:create, :after, :send_welcome_email_and_confirmation)
```

**Raison** : Éviter l'envoi d'emails lors de la création d'utilisateurs de test en développement.

---

## 📝 Templates

### HTML : `app/views/user_mailer/welcome_email.html.erb`

**Caractéristiques** :
- Template responsive (compatible mobile)
- Design professionnel cohérent avec les autres emails
- Liens vers les principales sections (événements, initiations, boutique)

**Contenu typique** :
- Message de bienvenue personnalisé
- Présentation de l'association
- Liens vers :
  - Événements à venir
  - Initiations
  - Boutique
  - Profil utilisateur
- Prochaines étapes suggérées

### Text : `app/views/user_mailer/welcome_email.text.erb`

**Version texte** pour les clients email ne supportant pas HTML.

**Contenu** : Similaire au HTML mais format texte simple avec liens URL complets.

---

## 🎯 Cas d'Usage

### Inscription Standard

**Flux** :
1. Utilisateur s'inscrit via `RegistrationsController#create`
2. Compte User créé (`User.create`)
3. Callback `after_create` déclenché
4. `send_welcome_email_and_confirmation` exécuté
5. Email de bienvenue envoyé (`deliver_later`)
6. Email de confirmation Devise envoyé

**Résultat** : L'utilisateur reçoit 2 emails :
- Email de confirmation (Devise)
- Email de bienvenue (UserMailer)

### Création via Seeds/Console

**Flux** :
1. Callback désactivé (`skip_callback`)
2. Utilisateurs créés
3. Callback réactivé (`set_callback`)

**Résultat** : Aucun email envoyé lors de la création.

---

## 🧪 Tests

**Fichier** : `spec/mailers/user_mailer_spec.rb`

**Scénarios testés** :
- ✅ Envoi de l'email avec bon destinataire
- ✅ Sujet correct
- ✅ Variables d'instance présentes (@user, @events_url)
- ✅ Templates HTML et text générés

**Exécution** :
```bash
bundle exec rspec spec/mailers/user_mailer_spec.rb
```

### Test d'Intégration

**Fichier** : `spec/requests/registrations_spec.rb`

**Vérification** :
- L'email de bienvenue est envoyé lors de l'inscription
- Utilisation de `deliver_now` en test (au lieu de `deliver_later`)

---

## 🔗 Intégration avec Devise

### Confirmation Email

**Ordre d'envoi** :
1. Email de confirmation Devise (en premier)
2. Email de bienvenue (immédiatement après)

**Raison** : Permettre à l'utilisateur de confirmer son email avant de recevoir le message de bienvenue (meilleure UX).

### Timing

**Envoi** : Immédiatement après création du compte

**Asynchrone** : `deliver_later` pour ne pas bloquer la création du compte

---

## 📊 Variables Disponibles dans les Templates

### @user

**Objet User complet** avec toutes les méthodes :

- `@user.email` : Email
- `@user.first_name` : Prénom
- `@user.last_name` : Nom
- `@user.full_name` : Nom complet (si méthode définie)
- `@user.created_at` : Date de création

### @events_url

**URL helper** : `events_url` → URL complète vers `/events`

**Utilisation** : Lien direct vers la liste des événements dans l'email

---

## 🎨 Personnalisation

### Contenu Personnalisé

**Prénom** : Utilisation de `@user.first_name` pour personnaliser le message

**Exemple** :
```erb
Bonjour <%= @user.first_name %>,

Bienvenue chez Grenoble Roller ! ...
```

### Liens Utiles

**Typiquement inclus** :
- Liste des événements (`@events_url`)
- Initiations
- Boutique
- Profil utilisateur
- FAQ

---

## ⚠️ Notes Importantes

### Doublons

**Pas de vérification** : Le callback s'exécute à chaque création, même si l'utilisateur existe déjà.

**Protection** : Devise vérifie l'unicité de l'email, donc pas de doublon réel.

### Seeds

**Important** : Toujours désactiver le callback lors de la création d'utilisateurs via seeds/console en développement.

**Exemple** :
```ruby
User.skip_callback(:create, :after, :send_welcome_email_and_confirmation)
# ... créer utilisateurs ...
User.set_callback(:create, :after, :send_welcome_email_and_confirmation)
```

### Performance

**Asynchrone** : `deliver_later` garantit que la création du compte n'est pas ralentie par l'envoi d'email.

**Queue** : Utilise la queue ActiveJob par défaut.

---

## 🔗 Références

- **Mailer** : `app/mailers/user_mailer.rb`
- **Templates HTML** : `app/views/user_mailer/welcome_email.html.erb`
- **Templates Text** : `app/views/user_mailer/welcome_email.text.erb`
- **Modèle User** : `app/models/user.rb` (callback `send_welcome_email_and_confirmation`)
- **Tests** : `spec/mailers/user_mailer_spec.rb`
- **Tests intégration** : `spec/requests/registrations_spec.rb`
- **Récapitulatif emails** : [`docs/04-rails/setup/emails-recapitulatif.md`](emails-recapitulatif.md)

---

## 🎯 Améliorations Futures Possibles

1. **Personnalisation selon rôle** : Contenu différent selon le rôle initial (USER, REGISTERED, etc.)
2. **Onboarding progressif** : Série d'emails de bienvenue (jour 1, jour 3, jour 7)
3. **Contenu dynamique** : Inclure les prochains événements dans l'email
4. **A/B Testing** : Tester différents sujets/formats pour optimiser l'engagement
5. **Tracking** : Suivre les ouvertures/clics (si service email tracking configuré)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30


