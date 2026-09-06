# Spécification Finale - Module Gestion des Initiations

**Dernière mise à jour** : 2026-08-14


**Date** : 2026-08-14  
**Statut** : ✅ Validé par les bénévoles  
**Version** : 1.0  
**Date cible MVP** : Janvier 2026

---

## 🎯 SYNTHÈSE DES DÉCISIONS MÉTIER

### Essai gratuit
- ✅ **Accès à vie** : Une seule tentative par utilisateur (contact staff possible pour exception)
- ✅ **Sans adhésion requise** pour l'essai
- ✅ **Adhésion obligatoire après essai** pour continuer
- ✅ **Modèle** : `free_trial_used` (boolean) dans `attendances`

### Structure des séances
- ✅ **UN SEUL niveau** (débutants/perfectionnement supprimé)
- ✅ **Horaire unique** : Samedi 10h15-12h00
- ✅ **Lieu unique** : Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble
- ✅ **Limite de places** : 30 participants maximum
- ✅ **Bénévoles** : Jusqu'à 10 présents (ne comptent pas dans les 30)

### Inscriptions
- ✅ **Multiples séances possibles** (s'il y a de la place)
- ✅ **Inscription jusqu'au dernier moment** (même samedi matin)
- ✅ **Annulation jusqu'au dernier moment**
- ✅ **Pas de date limite administrative**

### Matériel
- ✅ **Prêt de rollers uniquement** (pas de protections systématiques)
- ✅ **Pas d'inventaire à suivre** (gestion manuelle/papier)
- ✅ **Réservation avant initiation** (demande libre texte, gérée via WhatsApp)
- ✅ **Matériel = Phase 2**, pas MVP

### Communication
- ✅ **Canal WhatsApp** déjà existant
- ✅ **Rappels email** la veille à 19h (système existant)
- ✅ **Pas de logique spéciale d'annulation** (participants se réinscrivent manuellement)

### Permissions
- ✅ **Rôles INSTRUCTOR (30) et supérieurs** gèrent initiations
- ✅ **Peuvent** : voir liste participants, pointer présences, créer séances

### MVP et timeline
- ✅ **Priorités** :
  - Page inscription + gestion places (URGENT)
  - Suivi présences (URGENT)
  - Matériel = Phase 2
- ✅ **Date cible** : Janvier 2026

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Modèle de données

#### Extension STI : `Event::Initiation`

**Table `events` (extension avec STI)**

Champs NOUVEAUX :
- `type` : "Event::Initiation" (string, pour STI)
- `is_recurring` : true (boolean)
- `recurring_day` : "saturday" (string, enum)
- `recurring_time` : "10:15" (string)
- `season` : "2025-2026" (string)
- `recurring_start_date` : 2025-09-06 (date)
- `recurring_end_date` : 2026-08-31 (date)

Champs EXISTANTS réutilisés :
- `title` : "Initiation Roller - Samedi 6 septembre 2025"
- `location_text` : "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble"
- `meeting_lat` : 45.1891 (décimal)
- `meeting_lng` : 5.7317 (décimal)
- `max_participants` : 30 (integer)
- `status` : enum("draft", "published", "canceled")
- `start_at`, `end_at`, `duration_min`
- `created_at`, `updated_at`

#### Extension `attendances`

**Table `attendances` (extension existante)**

Champs NOUVEAUX :
- `free_trial_used` : boolean (default: false)
- `is_volunteer` : boolean (default: false) # Bénévole (ne compte pas dans les 30)
- `equipment_note` : text (nullable) # "Demande rollers taille 40"

Champs EXISTANTS réutilisés :
- `user_id`, `event_id`
- `status` : enum("registered", "present", "absent", "canceled", "no_show")
- `wants_reminder` : boolean (déjà existant)
- `created_at`, `updated_at`

---

## 📋 RÈGLES MÉTIER CLÉS

### Règle 1 : Essai gratuit

```ruby
# Validation avant inscription
if user.free_trial_used? == false
  # Peut utiliser essai gratuit OU avoir adhésion active
  can_register = true
elsif user.memberships.active_now.exists?
  # Essai utilisé mais adhésion active → OK
  can_register = true
else
  # Essai utilisé ET pas d'adhésion → ERREUR
  can_register = false
end
```

### Règle 2 : Limite de places

```ruby
# Places disponibles = 30 - participants (hors bénévoles)
available_places = 30 - attendances.where(is_volunteer: false, status: ['registered', 'present']).count

if available_places <= 0
  # Statut initiation = "full"
  # Blocage nouvelles inscriptions
  # Suggestion : liste d'attente (phase 2)
end
```

### Règle 3 : Bénévoles en plus

```ruby
# Bénévoles (is_volunteer = true) :
# - Comptent pour présence/absence tracking
# - Ne comptent PAS dans limite 30
# - Visibles dans les statuts admin
# - Rôle minimum : INSTRUCTOR (level 30)
```

---

## 📊 FONCTIONNALITÉS MVP (JANVIER 2026)

### 1️⃣ Gestion des séances d'initiation

**Créer une série récurrente (Admin/INSTRUCTOR)**

- Formulaire simple :
  - Date de début de saison (défaut : 1er sept)
  - Date de fin de saison (défaut : 31 août)
  - Jour de récurrence : samedi uniquement
  - Heure : 10h15 (fixe)
  - Durée : 1h45 (fixe)
  - Lieu : Gymnase Ampère (fixe)
  - Max participants : 30 (configurable)

**Générer automatiquement les séances**

- Créer une `Event::Initiation` pour chaque samedi entre les dates
- Exemple : 52 séances/saison (sept à août)
- Statut initial : "published"
- Pas d'interface (fait automatiquement via admin ou seed)

**Affichage et modification (Admin)**

- Lister toutes les séances d'une saison
- Éditer une séance individuelle :
  - Annuler (status → "canceled")
  - Changer max_participants
- Pas de modification horaire/lieu (fixes)

### 2️⃣ Page publique initiations

**Route & Vue** : `/initiations`

**Affichage des prochaines séances** (3 prochains mois)

Pour chaque séance :
- Date, heure, lieu
- Places disponibles (ex: "25/30 places" ou "COMPLET")
- Bouton "S'inscrire" (si connecté) ou "Connexion" (si pas connecté)
- Bouton "Annuler" (si inscrit)

**Informations statiques** (section infos)

- Horaires : samedi 10h15-12h00
- Lieu : Gymnase Ampère avec adresse
- Public : Adhérents, enfants dès 6 ans (adulte obligatoire)
- Tarif : Gratuit après adhésion 10€
- Essai gratuit : 1 essai sans adhésion
- Matériel : Possibilité de prêt rollers (contacter staff)
- Sécurité : Casque + protections fortement recommandés

### 3️⃣ Inscription aux initiations

**Formulaire d'inscription** (Utilisateur connecté)

- Choix séance : dropdown liste des séances disponibles
- Demande matériel : texte libre "Demande rollers taille 40" (ou rien)
- Case à cocher : "Je veux être rappelé la veille" (défaut : true)
- Champ enfant : sélectionner une adhésion enfant (optionnel)

**Validation** :

- Si pas adhésion ET essai utilisé → erreur "Adhésion requise"
- Si essai gratuit disponible → option "Utiliser mon essai" (optionnel)
- Si places complètes → disabled avec "COMPLET"

**Confirmation après inscription**

- Message : "Inscription confirmée pour [date]"
- Info : "Un rappel vous sera envoyé la veille"
- Lien vers profil inscriptions

### 4️⃣ Gestion des inscriptions (Admin)

**Interface admin** (ActiveAdmin)

- Lister toutes les séances d'une saison
- Pour chaque séance :
  - Voir la liste des inscrits :
    - Nom, email, statut présence
    - Colonne "Essai gratuit utilisé ?"
    - Colonne "Demande matériel" (texte libre)
    - Colonne "Bénévole ?"
  - Actions :
    - ✅ Pointer présence (present/absent/no_show)
    - ✅ Marquer comme bénévole (toggle is_volunteer)
    - ✅ Annuler inscription
    - ✅ Ajouter manuel (créer registration)

**Export**

- Bouton "Export CSV" → colonnes : nom, email, présence, matériel demandé
- Pour traitements Excel (relance, stats)

**Statuts présence**

- `registered` → Par défaut (inscrit mais pas pointé)
- `present` → Pointage le jour J
- `absent` → Marqué absent
- `no_show` → N'est pas venu (pour suivi)

### 5️⃣ Notifications

**Email** (existant, adapter)

- À l'inscription : Confirmation + détails pratiques
  - Sujet : "Inscription confirmée - Initiation roller samedi [date]"
  - Contenu : adresse, horaire, essai utilisé ?, matériel demandé
- Rappel la veille à 19h (job `EventReminderJob` existant)
  - Inclure infos matériel demandé
  - Lien vers page initiation

**WhatsApp** (manuel pour MVP)

- Pas d'automatisation (traité manuellement par staff)
- Les demandes matériel vont dans le formulaire (texte libre)

### 6️⃣ Dashboard bénévoles

**Vue simple** : `/admin/initiations/[id]`

- Liste participants du jour (statut registered)
- Cases à cocher "Présent" / "Absent"
- Colonne "Matériel demandé" (visuelle)
- Bouton "Sauvegarder présences"

---

## 🔐 SÉCURITÉ & VALIDATION

### Contrôles d'accès (Pundit)

- Consultation initiation : Tous
- Inscription : Utilisateur authentifié
- Gestion présence : INSTRUCTOR+ uniquement
- Modification séance : ADMIN uniquement

### Validations métier

- Essai gratuit : max 1 par utilisateur
- Adhésion : vérification avant confirmation
- Places : vérification temps réel
- Doublons : 1 inscription = 1 user + 1 event unique

### RGPD

- Données enfant : via adhésion existante
- Suppression : soft-delete si demande
- Consentement email : champ `wants_reminder`

---

## 📈 MÉTRIQUES À TRACKER (Optionnel)

- Taux participation : présents / inscrits
- Essais gratuits utilisés / saison
- Taux de remplissage : inscrits / 30 places
- Adhésions créées post-essai : X%
- Absence "no-show" : X%

---

## 🚀 ROADMAP COMPLÈTE

### MVP Phase 3A (janvier 2026) ✅

- ✅ Séances récurrentes (52/saison)
- ✅ Page initiations + inscription
- ✅ Suivi présences admin
- ✅ Essai gratuit + adhésion obligatoire
- ✅ Bénévoles non-comptabilisés
- ✅ Rappels email

### Phase 3B (février-mars 2026) 📅

- Matériel simple (tracking ou reste manuel)
- Liste d'attente (automatique si places libérées)
- Dashboard stats saison
- SMS notifications (Twilio)

### Phase 3C (avril+) 🔮

- Progression niveaux (si besoin)
- Certificats/badges présence
- Intégration Google Calendar
- Mobile app monitoring présences

---

## 📝 RÉFÉRENCES TECHNIQUES

### Modèles existants réutilisés

- `Event` : Base pour STI `Event::Initiation`
- `Attendance` : Extension avec `free_trial_used`, `is_volunteer`, `equipment_note`
- `Membership` : Vérification adhésion active
- `User` : Système d'authentification

### Systèmes existants réutilisés

- **Pundit** : Permissions (INSTRUCTOR+)
- **ActiveAdmin** : Interface admin
- **EventMailer** : Notifications email
- **EventReminderJob** : Rappels automatiques
- **Bootstrap 5** : UI responsive

---

## ✅ CHECKLIST AVANT DÉVELOPPEMENT

### Confirmation avec bénévoles

- ✅ Confirmé : créneaux parallèles = NON (1 seul niveau)
- ✅ Confirmé : limite 30 + jusqu'à 10 bénévoles en sus
- ✅ Confirmé : essai à vie (contact staff possible)
- ✅ Confirmé : adhésion obligatoire après essai
- ✅ Confirmé : matériel = phase 2

### Configuration Rails

- ✅ Gem dependencies reviewed
- ✅ Pundit setup OK
- ✅ ActiveAdmin resource structure
- ✅ Email templates prepared

### BD

- ✅ Migrations validées
- ✅ Seeds data created
- ✅ Indexes optimized
- ✅ Unique constraints tested

### Testing

- ✅ Unit tests models
- ✅ Integration tests controller
- ✅ Permission tests (Pundit)
- ✅ Validation tests métier

---

## 🎯 RÉSUMÉ EN 1 PAGE

| Élément | Périmètre |
|---------|-----------|
| Séances | 52/saison (samedi 10h15-12h00) |
| Places | 30 max + bénévoles illimités |
| Niveaux | 1 seul (pas de distinction) |
| Essai | Gratuit à vie (1x) → adhésion obligatoire |
| Inscription | Multiples séances, jusqu'au dernier moment |
| Matériel | Demande libre texte (gestion WhatsApp) |
| Admin | Liste participants + pointage présence (ActiveAdmin) |
| Notifs | Email J-1 à 19h + WhatsApp manuel |
| Permissions | INSTRUCTOR+ pour gestion |
| Intégration | Réutilise Event, Attendance, Membership existants |

**Code réutilisé = 80% (très peu de nouveau) → Livraison rapide**

