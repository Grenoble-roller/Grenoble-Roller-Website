---
title: "Système de Liste d'Attente (Waitlist) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["waitlist", "events", "initiations", "attendance"]
---

# Système de Liste d'Attente (Waitlist)

**Dernière mise à jour** : 2025-01-30

Ce document décrit le système complet de liste d'attente pour les événements et initiations quand ils sont complets.

---

## 📋 Vue d'Ensemble

Le système de liste d'attente permet aux utilisateurs de s'inscrire sur une liste quand un événement est complet. Quand une place se libère, la première personne en liste est notifiée et dispose de 24 heures pour confirmer son inscription.

### Fonctionnalités

- ✅ Inscription automatique sur liste d'attente quand événement complet
- ✅ Position automatique (ordre FIFO)
- ✅ Notification email quand place disponible
- ✅ Délai de 24h pour confirmer
- ✅ Conversion automatique en inscription si confirmé
- ✅ Refus possible (place libérée pour la personne suivante)
- ✅ Support enfants (adhésions enfant)
- ✅ Support équipement (roller_size)
- ✅ Support essai gratuit (initiations)
- ✅ Réorganisation automatique après annulations

---

## 🏗️ Architecture

### Modèle : `WaitlistEntry`

**Fichier** : `app/models/waitlist_entry.rb`

#### Attributs

| Attribut | Type | Description |
|----------|------|-------------|
| `user_id` | bigint | Utilisateur en liste d'attente |
| `event_id` | bigint | Événement concerné |
| `child_membership_id` | bigint (optional) | Adhésion enfant (si inscription pour enfant) |
| `status` | enum | Statut de l'entrée (voir ci-dessous) |
| `position` | integer | Position dans la liste (0 = première) |
| `notified_at` | timestamp | Date de notification (quand place disponible) |
| `needs_equipment` | boolean | Besoin d'équipement |
| `roller_size` | string | Taille rollers demandée |
| `wants_reminder` | boolean | Souhaite recevoir rappels |
| `use_free_trial` | boolean | Utiliser essai gratuit (initiations) |

#### Statuts (Enum)

```ruby
enum :status, {
  pending: "pending",      # En attente (pas encore notifié)
  notified: "notified",    # Notifié qu'une place est disponible
  converted: "converted",  # Converti en inscription (place prise)
  cancelled: "cancelled"   # Annulé par l'utilisateur
}
```

**Transitions** :
```
pending → notified → converted (confirmé)
pending → notified → pending (refusé, revient en attente)
pending → cancelled (annulé manuellement)
```

#### Relations

- `belongs_to :user`
- `belongs_to :event`
- `belongs_to :child_membership` (optional)

#### Validations

- `position` : présence, >= 0
- `user_id` : unicité scope `[:event_id, :child_membership_id]` (sauf cancelled)
- `event_is_full` : l'événement doit être complet pour s'inscrire
- `user_not_already_registered` : ne pas être déjà inscrit
- `child_membership_belongs_to_user` : si enfant, vérifier que c'est son enfant
- `roller_size` : présence si `needs_equipment?`, inclusion dans `RollerStock::SIZES`

#### Scopes

- `active` : Statuts `pending` ou `notified` (exclut converted et cancelled)
- `for_event(event)` : Pour un événement donné
- `ordered_by_position` : Tri par position puis date création
- `pending_notification` : En attente de notification (pending, notified_at nil)

#### Méthodes Métier

##### Instance

- `participant_name` : Nom du participant (adulte ou enfant)
- `for_child?` : Vérifie si c'est pour un enfant
- `notify!` : Notifie qu'une place est disponible (crée attendance "pending")
- `convert_to_attendance!` : Convertit en inscription active (attendance "registered")
- `refuse!` : Refuse la place (revient en pending, notifie la personne suivante)
- `cancel!` : Annule l'inscription (cancelled)

##### Classe

- `add_to_waitlist(...)` : Ajoute un utilisateur à la liste d'attente
- `notify_next_in_queue(event, count: 1)` : Notifie les N premières personnes
- `reorganize_positions(event)` : Réorganise les positions après annulation

---

## 🔄 Flux Utilisateur

### 1. Inscription sur Liste d'Attente

**Quand** : Utilisateur essaie de s'inscrire à un événement complet

**Processus** :
1. L'événement est complet (`event.full?` retourne `true`)
2. L'utilisateur clique sur "Rejoindre la liste d'attente"
3. `WaitlistEntry.add_to_waitlist(...)` est appelé
4. Vérifications :
   - Événement complet ✅
   - Pas déjà inscrit ✅
   - Pas déjà en liste d'attente (actif) ✅
5. Création de l'entrée avec position automatique
6. Message de confirmation affiché

**Position** : Dernière position = `max_position + 1`

### 2. Notification Place Disponible

**Quand** : Une place se libère (désinscription, annulation)

**Processus** :
1. `WaitlistEntry.notify_next_in_queue(event)` appelé automatiquement
2. Vérification : l'événement a des places disponibles
3. Récupération première personne `pending_notification` (ordre position)
4. Appel `waitlist_entry.notify!` :
   - Création d'une `Attendance` avec statut `"pending"` (verrouille la place)
   - Mise à jour `WaitlistEntry` : `status = "notified"`, `notified_at = now`
   - Envoi email `EventMailer.waitlist_spot_available`
5. Email contient lien de confirmation (24h pour répondre)

**Verrouillage** : L'attendance "pending" verrouille la place pour 24h

### 3. Confirmation (Acceptation)

**Quand** : Utilisateur clique sur "Confirmer" dans l'email ou sur le site

**Routes** :
- `POST /events/:id/convert_waitlist_to_attendance` (formulaire)
- `GET /events/:id/waitlist/confirm?waitlist_entry_id=xxx` (lien email, redirige vers POST)

**Processus** :
1. Vérification : `WaitlistEntry` est `notified?` et appartient à l'utilisateur
2. Appel `waitlist_entry.convert_to_attendance!` :
   - Trouve l'attendance "pending" créée lors de la notification
   - Met à jour `attendance.status = "registered"` (bypass validations)
   - Met à jour `WaitlistEntry.status = "converted"`
   - Déclenche `event.notify_next_waitlist_entry` si nécessaire
3. Message de succès affiché
4. Redirection vers l'événement

**Délai** : 24 heures après `notified_at`

### 4. Refus (Déclin)

**Quand** : Utilisateur clique sur "Refuser" dans l'email ou sur le site

**Routes** :
- `POST /events/:id/refuse_waitlist` (formulaire)
- `GET /events/:id/waitlist/decline?waitlist_entry_id=xxx` (lien email, redirige vers POST)

**Processus** :
1. Vérification : `WaitlistEntry` est `notified?` et appartient à l'utilisateur
2. Appel `waitlist_entry.refuse!` :
   - Trouve et supprime l'attendance "pending"
   - Remet `WaitlistEntry.status = "pending"`, `notified_at = nil`
   - Déclenche `WaitlistEntry.notify_next_in_queue(event)` (notifie la personne suivante)
3. Message de confirmation affiché

### 5. Annulation Manuelle

**Quand** : Utilisateur clique sur "Quitter la liste d'attente"

**Route** : `DELETE /events/:id/leave_waitlist`

**Processus** :
1. Trouve l'entrée active pour l'utilisateur
2. Appel `waitlist_entry.cancel!` :
   - Met à jour `status = "cancelled"`
   - Déclenche `WaitlistEntry.reorganize_positions(event)`
3. Réorganisation des positions (toutes les entrées actives)

---

## 📧 Email de Notification

### EventMailer.waitlist_spot_available

**Template** :
- HTML : `app/views/event_mailer/waitlist_spot_available.html.erb`
- Text : `app/views/event_mailer/waitlist_spot_available.text.erb`

**Contenu** :
- Informations événement
- Nom du participant
- Lien de confirmation (24h valide)
- Lien de refus
- Délai : 24 heures pour confirmer

**Variables** :
- `@waitlist_entry`
- `@event`
- `@user`
- `@participant_name`
- `@expiration_time` (notified_at + 24h)

---

## 🛣️ Routes

### Événements Généraux (`EventsController`)

| Route | Méthode | Action | Description |
|-------|---------|--------|-------------|
| `/events/:id/join_waitlist` | POST | `join_waitlist` | Rejoindre la liste d'attente |
| `/events/:id/leave_waitlist` | DELETE | `leave_waitlist` | Quitter la liste d'attente |
| `/events/:id/convert_waitlist_to_attendance` | POST | `convert_waitlist_to_attendance` | Confirmer (convertir en inscription) |
| `/events/:id/refuse_waitlist` | POST | `refuse_waitlist` | Refuser la place |
| `/events/:id/waitlist/confirm` | GET | `confirm_waitlist` | Lien email confirmation (redirige vers POST) |
| `/events/:id/waitlist/decline` | GET | `decline_waitlist` | Lien email refus (redirige vers POST) |

### Initiations (`InitiationsController`)

Mêmes routes que pour les événements généraux.

---

## 🔐 Autorisations (Policies)

### EventPolicy

- `join_waitlist?` : Utilisateur connecté, événement complet
- `leave_waitlist?` : Propriétaire de l'entrée
- `convert_waitlist_to_attendance?` : Propriétaire, statut `notified`
- `refuse_waitlist?` : Propriétaire, statut `notified`

### Event::InitiationPolicy

- `join_waitlist?` : Utilisateur connecté, événement complet, **et adhérent** (demande bénévoles). Pour les initiations, la liste d'attente est **réservée aux adhérents** : parent = adhésion adulte active ; enfant = adhésion enfant **active** uniquement (trial et pending ne peuvent pas rejoindre la liste d'attente). Les non-adhérents ne peuvent pas rejoindre la liste d'attente (ils peuvent uniquement s'inscrire directement si une place est libre, avec essai gratuit si disponible).
- `leave_waitlist?`, `convert_waitlist_to_attendance?`, `refuse_waitlist?` : comme `EventPolicy`.

---

## 🎯 Cas Particuliers

### Initiations

**Liste d'attente réservée aux adhérents** : Pour les initiations, seuls les adhérents (parent avec adhésion adulte active, ou enfant avec adhésion **active** uniquement) peuvent rejoindre la liste d'attente. Les enfants en trial ou pending ne peuvent pas rejoindre la liste d'attente. Cela évite le contournement : s'inscrire en liste d'attente sans cocher l'essai gratuit, confirmer à la libération d'une place, puis utiliser l'essai gratuit sur une autre initiation.

Pour les initiations (`Event::Initiation`), des validations spéciales sont bypassées lors de la conversion :

- `can_use_free_trial` : Déjà vérifié lors de l'inscription en liste d'attente
- `can_register_to_initiation` : Déjà vérifié lors de l'inscription

### Enfants

- Support complet via `child_membership_id`
- Validation que l'adhésion enfant appartient à l'utilisateur
- Nom du participant construit depuis `child_membership`

### Équipement

- `needs_equipment` : Besoin d'équipement
- `roller_size` : Taille rollers (validation dans `RollerStock::SIZES`)
- Préservé lors de la conversion en inscription

### Essai Gratuit

- `use_free_trial` : Pour initiations uniquement
- Préservé lors de la conversion
- Déjà vérifié lors de l'inscription en liste d'attente

---

## 🔄 Intégration avec Attendance

### Création Attendance "pending"

Quand une place devient disponible :

```ruby
attendance = event.attendances.build(
  user: user,
  child_membership_id: child_membership_id,
  status: "pending",  # Statut temporaire
  wants_reminder: wants_reminder,
  needs_equipment: needs_equipment,
  roller_size: roller_size,
  free_trial_used: use_free_trial
)
attendance.save(validate: false)  # Bypass validations
```

### Conversion en "registered"

Quand l'utilisateur confirme :

```ruby
attendance.update_column(:status, "registered")  # Bypass validations
```

**Note** : Les validations sont bypassées car elles ont déjà été vérifiées lors de l'inscription en liste d'attente.

---

## 📊 Comptage et Affichage

### Dans les Vues

**Variables d'instance dans `EventsController#show` et `InitiationsController#show`** :

- `@user_waitlist_entries` : Toutes les entrées actives de l'utilisateur
- `@user_waitlist_entry` : Entrée pour l'utilisateur adulte (si existe)
- `@child_waitlist_entries` : Entrées pour les enfants (si existent)

### Affichage Conditionnel

- Si événement complet + utilisateur en liste d'attente → Afficher "Vous êtes en liste d'attente (position X)"
- Si événement complet + utilisateur pas en liste → Afficher "Rejoindre la liste d'attente"
- Si événement complet + utilisateur notifié → Afficher "Place disponible ! Confirmer"

---

## 🧪 Tests

**Fichiers de tests** : `spec/models/waitlist_entry_spec.rb` (à créer si nécessaire)

**Scénarios à tester** :
- Création avec position automatique
- Notification et création attendance "pending"
- Conversion en inscription active
- Refus et notification suivante
- Annulation et réorganisation
- Validation unicité user/event/child
- Validation événement complet
- Support enfants
- Support équipement
- Support essai gratuit (initiations)

---

## 📝 Notes Techniques

### Hashid

Le modèle utilise `include Hashid::Rails` pour générer des identifiants URL-friendly :
- `waitlist_entry.to_hashid` : Génère l'ID hashé
- `WaitlistEntry.find_by_hashid(hashid)` : Trouve depuis l'ID hashé

### Logging

Toutes les actions importantes sont loggées :
- Création entrée
- Notification
- Conversion
- Refus
- Erreurs

### Performance

- Scopes optimisés avec `includes(:child_membership)` pour éviter N+1
- Utilisation de `update_column` pour bypass validations (conversion)
- Réorganisation des positions après annulation (requête unique)

---

## 🔗 Références

- **Modèle** : `app/models/waitlist_entry.rb`
- **Contrôleurs** : `app/controllers/events_controller.rb`, `app/controllers/initiations_controller.rb`
- **Mailer** : `app/mailers/event_mailer.rb` (méthode `waitlist_spot_available`)
- **Policies** : `app/policies/event_policy.rb`, `app/policies/event/initiation_policy.rb`
- **Modèle Event** : `app/models/event.rb` (méthode `notify_next_waitlist_entry`)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

