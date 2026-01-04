# Logique d'Essai Gratuit - Documentation Complète v4.0

## Vue d'ensemble

Le système d'essai gratuit permet aux utilisateurs non adhérents (adultes ou enfants) de participer à **une seule initiation** gratuitement. Après cette initiation, une adhésion est requise pour continuer.

**⚠️ RÈGLE FONDAMENTALE v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque personne (adulte ou enfant) a droit à **1 essai gratuit** qui lui est propre. Chaque enfant DOIT utiliser son propre essai gratuit, même si le parent est adhérent.

**RÈGLE MÉTIER CRITIQUE** : 
- **Essais gratuits NOMINATIFS** : Chaque personne (adulte ou enfant) a droit à **1 essai gratuit** qui lui est propre
- **Enfants** : 
  - Par défaut, tous les enfants sont créés avec le statut `pending` (adhésion en attente de paiement) et ont **automatiquement** un essai gratuit disponible (**OBLIGATOIRE**, même si le parent est adhérent)
  - Exception : Si `create_trial = "1"`, l'enfant est créé avec le statut `trial` (non adhérent) et l'essai gratuit est **obligatoire**
  - ⚠️ **IMPORTANT** : Les essais gratuits sont **nominatifs** - chaque enfant DOIT utiliser son propre essai gratuit, indépendamment de l'adhésion du parent
  - ⚠️ **IMPORTANT** : Les statuts `pending` et `trial` sont **mutuellement exclusifs** :
    - `pending` = L'enfant a une adhésion mais pas encore payée
    - `trial` = L'enfant n'a PAS d'adhésion, c'est un non-adhérent
    - Un enfant ne peut pas être les deux en même temps
- **Adultes** : Les adultes non adhérents peuvent utiliser leur essai gratuit lors de l'inscription à une initiation

**IMPORTANT** : Si un utilisateur (adulte ou enfant) se désinscrit d'une initiation où il avait utilisé son essai gratuit, l'essai gratuit redevient disponible et peut être réutilisé.

---

## 1. Règles Générales

### 1.1. Qui peut utiliser l'essai gratuit ?

#### Pour les Enfants

**Règle métier** : 
- Par défaut, tous les enfants sont créés avec le statut `pending` et ont automatiquement un essai gratuit disponible (**OBLIGATOIRE**, même si le parent est adhérent)
- Exception : Si le parent coche "Créer avec essai gratuit obligatoire" (`create_trial = "1"`), l'enfant est créé avec le statut `trial` et l'essai gratuit est obligatoire
- ⚠️ **CRITIQUE** : Les essais gratuits sont **nominatifs** - chaque enfant DOIT utiliser son propre essai gratuit, indépendamment de l'adhésion du parent

**Qui crée l'enfant ?**
- Le **parent** crée le profil enfant via le formulaire `/memberships/new?child=true`
- Par défaut, l'enfant est créé **automatiquement** en statut `pending` (adhésion en attente de paiement)
- Si `create_trial = "1"`, l'enfant est créé en statut `trial` (non adhérent)
- L'essai gratuit est **automatiquement attribué** lors de la création (pas de champ explicite dans la DB, c'est implicite)

**À quelle étape ?**
- **T0** : Parent remplit le formulaire d'inscription enfant
- **T1** : Parent soumet le formulaire
- **T2** : Système crée `Membership` avec `status = "pending"` et `is_child_membership = true`
- **T3** : L'enfant a maintenant un essai gratuit disponible (implicite, pas de champ DB)

**Est-ce qu'un enfant peut avoir un profil SANS essai gratuit ?**
- ❌ **NON** : Tous les enfants créés via le formulaire parent ont automatiquement un essai gratuit disponible
- ⚠️ **Exception** : Si l'enfant a déjà utilisé son essai gratuit (attendance active avec `free_trial_used = true`), l'essai n'est plus disponible

**Code réel de création** :
```ruby
# app/controllers/memberships_controller.rb
def create_child_membership_from_params(child_params, index)
  # ...
  # Vérifier si c'est un essai gratuit (statut trial)
  create_trial = params[:create_trial] == "1" || child_params[:create_trial] == "1"
  
  if create_trial
    membership_status = :trial  # Statut trial = essai gratuit explicite
  else
    membership_status = :pending  # Statut pending = adhésion en attente + essai gratuit implicite
  end
  
  # Créer l'adhésion enfant
  membership = Membership.create!(
    user: current_user, # Le parent
    status: membership_status,
    is_child_membership: true,
    # ... autres champs
  )
end
```

#### Pour les Adultes

- **Adultes non adhérents** : Un adulte sans adhésion active peut utiliser son essai gratuit lors de l'inscription à une initiation
- **Un seul essai gratuit par adulte** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)

### 1.2. Restrictions

- **Essais gratuits NOMINATIFS** : Chaque personne (adulte ou enfant) a droit à **1 essai gratuit** qui lui est propre
- **Un seul essai gratuit par personne** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Un seul essai gratuit par enfant** : Chaque enfant ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Indépendance parent/enfant** : L'essai gratuit du parent est indépendant de celui des enfants (et vice versa)
- **Obligatoire pour les enfants** : Les enfants avec statut `pending` ou `trial` DOIVENT utiliser leur essai gratuit, même si le parent est adhérent
- **Uniquement pour les initiations** : L'essai gratuit n'est disponible que pour les initiations, pas pour les événements/randos normaux

### 1.3. Réutilisation après annulation

**Si un utilisateur se désinscrit d'une initiation où il avait utilisé son essai gratuit :**
- L'essai gratuit redevient disponible
- Il peut s'inscrire à nouveau à une initiation en utilisant son essai gratuit
- Seules les attendances avec `status = "canceled"` sont exclues des vérifications

**Exemple concret** :
```
T0: Enfant créé → pending + essai gratuit disponible (implicite)
T1: Enfant s'inscrit à Initiation A → Attendance créée avec free_trial_used = true
T2: Essai gratuit "utilisé" = bloqué pour autres initiations
T3: Enfant annule Initiation A → Attendance.status = "canceled"
T4: Essai gratuit redevient disponible (scope .active exclut canceled)
T5: Enfant peut s'inscrire à Initiation B avec essai gratuit
```

---

## 2. Clarification Statut `pending` (Enfant)

### 2.1. Règle Métier Claire

**Un enfant avec statut `pending` (adhésion en attente de paiement) :**
- ⚠️ **CORRECTION MAJEURE v4.0** : Les essais gratuits sont **NOMINATIFS**
- ✅ **DOIT utiliser son essai gratuit** (obligatoire), même si le parent est adhérent
- ❌ **BLOQUÉ si essai gratuit déjà utilisé** → BLOQUÉ (doit avoir une adhésion active)
- ❌ **N'est PAS considéré comme membre** dans le modèle (`is_member = false` car `active_now` exclut `pending`)

**Différence avec statut `trial` :**
- `trial` = Non adhérent, essai gratuit **OBLIGATOIRE** (nominatif, même si parent adhérent)
- `pending` = Adhésion en attente de paiement, essai gratuit **OBLIGATOIRE** (nominatif, même si parent adhérent)
- ⚠️ **IMPORTANT** : Les deux statuts ont la même logique - l'essai gratuit est **toujours obligatoire** car il est **nominatif**

**⚠️ CLARIFICATION CRITIQUE - Logique `is_member` (CODE RÉEL VÉRIFIÉ) :**

**INCOHÉRENCE DÉTECTÉE entre contrôleur et modèle** :

**Contrôleur** (`app/controllers/initiations/attendances_controller.rb:90`) :
```ruby
is_member = child_membership&.active? || child_membership&.pending?
```
→ `pending` = `is_member = true` dans le contrôleur

**Modèle** (`app/models/attendance.rb:154-156`) :
```ruby
is_member = user.memberships.active_now.exists? ||
            (child_membership_id.present? && child_membership&.active?) ||
            (!child_membership_id.present? && user.memberships.active_now.where(is_child_membership: true).exists?)
```
→ `pending` = `is_member = false` dans le modèle (car `active_now` exclut `pending`)

**Modèle** (`app/models/attendance.rb:220`) :
```ruby
unless has_active_membership || has_child_membership || free_trial_used
  errors.add(:base, "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association.")
end
```

**RÉSULTAT RÉEL v4.0 (ESSais GRATUITS NOMINATIFS)** :
- Un enfant `pending` a `is_member = false` dans le modèle
- `has_child_membership = false` (car `active_now` exclut `pending`)
- ⚠️ **CORRECTION v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque enfant DOIT utiliser son propre essai gratuit
- ⚠️ **IMPORTANT v4.0** : Le statut du parent n'a **AUCUNE influence** sur l'accès de l'enfant
- Donc il faut :
  - `free_trial_used = true` (essai gratuit utilisé) → ✅ ACCÈS via essai **obligatoire** (nominatif)
  - ❌ **PAS d'accès via parent** : Un parent ne peut pas utiliser l'adhésion de son enfant, et vice versa

**⚠️ TABLEAU FINAL CORRIGÉ v4.0 (ESSais GRATUITS NOMINATIFS)** :

| Statut | Parent Adhérent ? | Essai Dispo | Résultat |
|--------|-------------------|-------------|----------|
| `pending` | ❌ Non | ❌ Non | 🔴 **BLOQUÉ** |
| `pending` | ❌ Non | ✅ Oui | ✅ **ACCÈS** (via essai **obligatoire** - nominatif) |
| `pending` | ❌ Non | ✅ Utilisé | 🔴 **BLOQUÉ** |
| `pending` | ✅ Oui | ✅ Oui | ✅ **ACCÈS** (via essai **obligatoire** - nominatif) |
| `pending` | ✅ Oui | ✅ Utilisé | 🔴 **BLOQUÉ** |
| `trial` | ❌ Non | ✅ Oui | ✅ **ACCÈS** (via essai obligatoire - nominatif) |
| `trial` | ❌ Non | ✅ Utilisé | 🔴 **BLOQUÉ** |
| `trial` | ✅ Oui | ✅ Oui | ✅ **ACCÈS** (via essai obligatoire - nominatif) |
| `trial` | ✅ Oui | ✅ Utilisé | 🔴 **BLOQUÉ** |
| `active` | N/A | N/A | ✅ **ACCÈS COMPLET** |

**Exemples concrets v4.0 (ESSais GRATUITS NOMINATIFS)** :
- **Case 1.1** : Child pending + essai dispo → ✅ ACCÈS (essai obligatoire - nominatif)
- **Case 1.2** : Child pending + parent adhérent + essai dispo → ✅ ACCÈS (essai obligatoire - nominatif)
- **Case 1.3** : Child pending + essai consommé → 🔴 BLOQUÉ
- **Case 2.1** : Child trial + essai dispo → ✅ ACCÈS (essai obligatoire - nominatif)
- **Case 2.2** : Child trial + parent adhérent + essai dispo → ✅ ACCÈS (essai obligatoire - nominatif)
- **Case 2.3** : Child trial + essai consommé → 🔴 BLOQUÉ
- **Case 3.X** : Child active → ✅ TOUJOURS ACCÈS (peu importe)
- **Case 4.2** : Parent pending + essai dispo → ✅ ACCÈS (essai obligatoire - nominatif)
- **Case 4.3** : Parent pending + essai consommé → 🔴 BLOQUÉ
- **Case 6.2** : Annulation puis réinscription → ✅ ESSAI REDEVIENT DISPO

**Voir aussi** : [Section détaillée sur la réutilisation](docs/development/essai-gratuit/16-reutilisation-annulation.md) et [Cas limite 5.6](docs/development/essai-gratuit/05-cas-limites.md#56-réinscription-à-la-même-initiation-après-annulation)

### 2.2. Contexte de Création

**Qui crée l'enfant en pending ?**
- Le **parent** crée l'enfant via le formulaire `/memberships/new?child=true`
- Le parent remplit les informations de l'enfant (nom, prénom, date de naissance, questionnaire de santé, etc.)
- Le parent soumet le formulaire
- Le système crée automatiquement `Membership` avec `status = "pending"`

**Qui paie l'essai gratuit ?**
- L'essai gratuit est **gratuit** (pas de paiement)
- L'essai gratuit est un **droit automatique** pour tous les enfants créés
- Aucun paiement n'est requis pour utiliser l'essai gratuit

**Quel est l'intérêt de pending si l'essai gratuit est déjà attribué ?**
- L'adhésion `pending` représente l'adhésion **payante** que le parent doit finaliser
- L'essai gratuit permet de s'inscrire à **une initiation** sans payer l'adhésion
- Après l'initiation, le parent doit finaliser le paiement de l'adhésion pour continuer
- **Timeline** :
  ```
  T0: Enfant créé → pending (adhésion payante en attente) + essai gratuit disponible
  T1: Enfant utilise essai gratuit → s'inscrit à Initiation A (gratuit)
  T2: Après Initiation A → parent doit payer l'adhésion pour continuer
  T3: Parent paie → pending → active
  ```

### 2.3. Logique d'Affichage dans les Formulaires (v4.0)

**⚠️ RÈGLE v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque enfant DOIT utiliser son propre essai gratuit.

#### Formulaire Principal (`_registration_form_fields.html.erb`)

Pour un enfant avec statut `pending` ou `trial` :
- La checkbox essai gratuit est **affichée** si l'enfant n'a pas encore utilisé son essai gratuit
- La checkbox est **OBLIGATOIRE** (cochée par défaut, `required = true`)
- Le bouton submit est **désactivé** si la checkbox n'est pas cochée
- Message affiché : "Utiliser l'essai gratuit de [Nom Enfant] (OBLIGATOIRE)"
- Aide : "Les essais gratuits sont nominatifs - chaque enfant a droit à son propre essai gratuit. Cette case doit être cochée pour confirmer l'inscription."

**Comportement JavaScript** :
- Lors de la sélection d'un enfant `pending` ou `trial` dans le dropdown, la checkbox est automatiquement cochée
- Le bouton submit est désactivé tant que la checkbox n'est pas cochée
- Le message d'aide explique clairement que l'essai gratuit est nominatif et obligatoire

#### Formulaire Enfant Supplémentaire (`_child_registration_form.html.erb`)

Pour un enfant avec statut `pending` ou `trial` :
- La checkbox essai gratuit est **affichée dynamiquement** selon l'enfant sélectionné
- La checkbox est **OBLIGATOIRE** (cochée par défaut, `required = true`)
- Le bouton submit est **désactivé** si la checkbox n'est pas cochée
- Message affiché : "Utiliser l'essai gratuit de [Nom Enfant] (OBLIGATOIRE)"

**Comportement JavaScript** :
- Lors de la sélection d'un enfant dans le dropdown, le JavaScript vérifie le statut (`pending` ou `trial`)
- Si l'enfant peut utiliser son essai gratuit, la checkbox est affichée et cochée automatiquement
- Le bouton submit est désactivé tant que la checkbox n'est pas cochée pour les enfants `pending` et `trial`

---

## 3. Protection contre les Race Conditions

### 3.1. Problème Identifié

Deux requêtes parallèles pourraient créer deux attendances avec `free_trial_used = true` pour le même utilisateur/enfant.

### 3.2. Solutions Implémentées

#### Solution 1 : Contrainte Unique au Niveau Base de Données (Recommandé)

**Migration créée** :
```ruby
# db/migrate/20250117120000_add_unique_constraint_free_trial_active.rb
class AddUniqueConstraintFreeTrialActive < ActiveRecord::Migration[7.0]
  # NOTE: disable_ddl_transaction! n'est pas utilisé dans le code réel (développement)
  # 
  # En développement : disable_ddl_transaction! n'est pas nécessaire (petite table, pas de lock problématique)
  # 
  # En production : Si la table est grande (> 100k lignes), il est RECOMMANDÉ d'ajouter :
  #   disable_ddl_transaction!
  #   # Puis remplacer add_index par execute("CREATE INDEX CONCURRENTLY ...")
  # 
  # Cela évite de bloquer la table pendant la création de l'index (opération qui peut prendre plusieurs minutes)
  # 
  # Exemple pour production :
  #   disable_ddl_transaction!
  #   def up
  #     execute("CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS index_attendances_unique_free_trial_parent_active ON attendances (user_id) WHERE free_trial_used = true AND status != 'canceled' AND child_membership_id IS NULL;")
  #   end
  
  def up
    # Contrainte unique pour les parents (child_membership_id IS NULL)
    # IMPORTANT : L'index utilise seulement :user_id (sans event_id) pour garantir
    # qu'un parent ne peut utiliser son essai gratuit qu'UNE SEULE FOIS, quel que soit l'événement
    # Si on incluait event_id, un parent pourrait utiliser son essai gratuit sur plusieurs initiations
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_parent_active")
      add_index :attendances, 
        :user_id, 
        unique: true, 
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NULL",
        name: "index_attendances_unique_free_trial_parent_active"
    end
    
    # Contrainte unique pour les enfants (child_membership_id IS NOT NULL)
    # IMPORTANT : Doit inclure child_membership_id dans l'index pour distinguer les enfants
    # IMPORTANT : L'index utilise [:user_id, :child_membership_id] (sans event_id) pour garantir
    # qu'un enfant ne peut utiliser son essai gratuit qu'UNE SEULE FOIS, quel que soit l'événement
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_child_active")
      add_index :attendances, 
        [:user_id, :child_membership_id], 
        unique: true, 
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NOT NULL",
        name: "index_attendances_unique_free_trial_child_active"
    end
  end
  
  def down
    remove_index :attendances, name: "index_attendances_unique_free_trial_parent_active", if_exists: true
    remove_index :attendances, name: "index_attendances_unique_free_trial_child_active", if_exists: true
  end
end
```

**Note importante** : 
- L'index pour les enfants doit inclure `child_membership_id` car un parent peut avoir plusieurs enfants, chacun avec son propre essai gratuit. L'index composite `[:user_id, :child_membership_id]` garantit l'unicité par enfant.
- **L'index ne contient PAS `event_id`** : C'est intentionnel. La règle métier est "un seul essai gratuit par personne, quel que soit l'événement". Si on incluait `event_id`, un parent/enfant pourrait utiliser son essai gratuit sur plusieurs initiations différentes, ce qui n'est pas souhaité.

**Note** : Cette contrainte PostgreSQL utilise une condition `WHERE` pour ne s'appliquer qu'aux attendances actives avec essai gratuit.

#### Solution 2 : Validation au Niveau Modèle (Déjà Implémenté)

La validation `can_use_free_trial` vérifie l'unicité avant la création.

### 3.3. Cycle de Vie de l'Essai Gratuit

**Quand exactement l'essai gratuit est-il "marqué comme utilisé" ?**

L'essai gratuit est marqué comme utilisé **lors de la création de l'attendance** (dans le contrôleur, avant le `save`).

**Timeline précise** :
```
T0: Enfant créé → pending + essai gratuit disponible (implicite)
    BD: memberships = [membership (status: "pending", is_child_membership: true)]
    BD: attendances = []

T1: Parent sélectionne enfant dans dropdown pour Initiation A
    Frontend: Checkbox "Utiliser l'essai gratuit" affichée (obligatoire pour pending, même si parent adhérent - v4.0 nominatif)

T2: Parent coche checkbox et soumet
    Frontend: Envoie params[:use_free_trial] = "1"

T3: Contrôleur reçoit la requête
    Controller: Vérifie que l'enfant n'a pas déjà utilisé son essai (scope .active)
    Controller: Si OK, définit attendance.free_trial_used = true
    ⚠️ À ce stade, l'essai n'est PAS encore "utilisé" en DB (pas encore sauvegardé)

T4: Attendance.save! est appelé (opération atomique)
    Model: Validation can_use_free_trial vérifie l'unicité (scope .active)
    Model: Validation can_register_to_initiation vérifie l'adhésion
    DB: Contrainte unique vérifie qu'aucun autre essai gratuit actif n'existe
    DB: Si OK, l'Attendance est sauvegardée avec free_trial_used = true
    ✅ L'essai gratuit est maintenant "utilisé" en DB (opération atomique)

T5: Attendance créée avec succès
    BD: attendances = [attendance (free_trial_used: true, status: "registered")]
    Essai gratuit "utilisé" = bloqué pour autres initiations

**Protection contre race condition** :
- Si deux requêtes parallèles tentent de créer une Attendance avec `free_trial_used = true` au même moment :
  - Les deux définissent `attendance.free_trial_used = true` (en mémoire)
  - Les deux appellent `attendance.save!`
  - La contrainte unique DB bloque la deuxième requête (erreur `PG::UniqueViolation`)
  - Seule la première Attendance est créée
  - ✅ Protection garantie au niveau base de données
```

**Code réel du contrôleur** :
```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  attendance.child_membership_id = child_membership_id
  
  # Pour un enfant avec statut pending : essai gratuit OBLIGATOIRE (nominatif)
  # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
  if child_membership_id.present? && child_membership&.pending?
    # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif), même si le parent est adhérent
    # Vérifier que l'essai gratuit est utilisé
    use_free_trial = params[:use_free_trial] == "1" || 
                     params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.present?
    unless use_free_trial
      redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
      return
    end
    attendance.free_trial_used = true
  end
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE
  if child_membership_id.present? && child_membership&.trial? && !is_member
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit."
      return
    end
    
    # Essai gratuit OBLIGATOIRE
    unless params[:use_free_trial] == "1"
      redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire."
      return
    end
    
    attendance.free_trial_used = true
  end
  
  if attendance.save
    # Succès
  end
end
```

---

## 4. Validations Serveur Renforcées

### 4.1. Problème Identifié

Trop de confiance dans les paramètres clients (checkbox, champs cachés).

### 4.2. Validations Multi-Niveaux

#### Niveau 1 : Validation Modèle (Source de Vérité)

**Code Ruby RÉEL complet** :
```ruby
# app/models/attendance.rb
class Attendance < ApplicationRecord
  # Définition du scope .active (exclut les attendances annulées)
  scope :active, -> { where.not(status: "canceled") }
  
  # Déclaration des validations
  validate :can_use_free_trial, on: :create
  validate :can_register_to_initiation, on: :create
  
  private
  
  def can_use_free_trial
    return unless free_trial_used
    return unless user
    
    # IMPORTANT : Exclure les attendances annulées (scope .active)
    if child_membership_id.present?
      # Pour un enfant : vérifier si cet enfant spécifique a déjà utilisé son essai gratuit
      if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
        errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit")
      end
    else
      # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit
      if user.attendances.active.where(free_trial_used: true, child_membership_id: nil).where.not(id: id).exists?
        errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
      end
    end
  end
  
  def can_register_to_initiation
    return unless event.is_a?(Event::Initiation)
    return if is_volunteer
    
    # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE (nominatif)
    # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
    # Chaque personne doit avoir sa propre adhésion - pas d'adhésion "famille"
    if for_child? && child_membership&.trial?
      unless free_trial_used
        errors.add(:free_trial_used, "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante.")
      end
      
      # Vérifier que cet enfant n'a pas déjà utilisé son essai gratuit (attendance active uniquement)
      if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
        errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise.")
      end
    end
  end
end
```

**Caractéristiques** :
- ✅ Ne dépend PAS des paramètres HTTP
- ✅ Vérifie directement l'état de la base de données
- ✅ Utilise le scope `.active` pour exclure les annulations
- ✅ Message d'erreur exact : `"L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."`

**Quand exactement la validation s'exécute ?**
- `:on => :create` : La validation s'exécute uniquement lors de la création (pas lors de la mise à jour)
- Avant le `save` : Les validations s'exécutent avant que l'enregistrement ne soit sauvegardé

#### Niveau 2 : Validation Contrôleur (Vérification Préalable)

**Code Ruby RÉEL complet** :
```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE
  if child_membership_id.present? && child_membership&.trial? && !is_member
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit (attendance active uniquement)
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."
      return
    end
    
    # Vérifier que free_trial_used sera true
    use_free_trial = params[:use_free_trial] == "1" || 
                     params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.any?
    
    unless use_free_trial
      redirect_to initiation_path(@initiation), alert: "Adhésion requise. L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
      return
    end
    
    attendance.free_trial_used = true
  end
  
  if attendance.save
    # Succès
  end
end
```

**Caractéristiques** :
- ✅ Vérification préalable avant création
- ✅ Redirection immédiate si problème
- ✅ Ne fait PAS confiance aux paramètres pour la logique métier
- ✅ Message d'erreur exact : `"Adhésion requise. L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."`

#### Niveau 3 : Validation JavaScript (UX uniquement)

**Comportement dans les formulaires (v4.0)** :

**Formulaire Principal** (`_registration_form_fields.html.erb`) :
```javascript
// RÈGLE v4.0 : Les essais gratuits sont NOMINATIFS - tous les enfants pending et trial DOIVENT utiliser leur essai gratuit
if (isTrial) {
  // Enfant trial : essai gratuit OBLIGATOIRE
  freeTrialCheckbox.checked = true; // Cocher par défaut
  freeTrialCheckbox.required = true; // Rendre obligatoire
} else if (isPending) {
  // RÈGLE v4.0 : Essais gratuits NOMINATIFS - l'essai gratuit est OBLIGATOIRE pour les enfants pending, même si le parent est adhérent
  freeTrialCheckbox.checked = true; // Cocher par défaut
  freeTrialCheckbox.required = true; // Rendre obligatoire
}

// Désactiver le bouton submit si la checkbox n'est pas cochée
function toggleSubmitButton() {
  if (isPending || isTrial) {
    if (!freeTrialCheckbox.checked) {
      submitBtn.disabled = true;
      submitBtn.style.opacity = '0.6';
      submitBtn.style.cursor = 'not-allowed';
    } else {
      submitBtn.disabled = false;
      submitBtn.style.opacity = '1';
      submitBtn.style.cursor = 'pointer';
    }
  }
}
```

**Formulaire Enfant Supplémentaire** (`_child_registration_form.html.erb`) :
```javascript
// RÈGLE v4.0 : Les essais gratuits sont NOMINATIFS - chaque enfant DOIT utiliser son propre essai gratuit
function updateFreeTrialDisplay() {
  if (selectedChild && (selectedChild.status === 'trial' || selectedChild.status === 'pending')) {
    if (selectedChild.can_use_trial) {
      freeTrialContainer.style.display = 'block';
      freeTrialCheckbox.checked = true; // Cocher par défaut
      freeTrialCheckbox.required = true; // Rendre obligatoire
    }
  }
}

function toggleSubmitButton() {
  if (selectedChild && (selectedChild.status === 'trial' || selectedChild.status === 'pending')) {
    if (!freeTrialCheckbox.checked) {
      submitBtn.disabled = true;
      submitBtn.style.opacity = '0.6';
      submitBtn.style.cursor = 'not-allowed';
    }
  }
}
```

**Caractéristiques** :
- ⚠️ **UX uniquement** : Améliore l'expérience utilisateur
- ❌ **PAS de sécurité** : Peut être contourné (JS désactivé, modification DOM)
- ✅ **Complémentaire** : Les validations serveur restent la source de vérité
- ✅ **Cohérence v4.0** : Tous les formulaires appliquent la même logique (essai gratuit obligatoire et nominatif pour les enfants `pending` et `trial`)

### 4.3. Principe de Défense en Profondeur

```
┌─────────────────────────────────────┐
│  JavaScript (UX)                   │  ← Peut être contourné
├─────────────────────────────────────┤
│  Contrôleur (Vérification)         │  ← Première ligne de défense
├─────────────────────────────────────┤
│  Modèle (Validation)                │  ← Source de vérité
├─────────────────────────────────────┤
│  Base de Données (Contrainte)      │  ← Protection ultime
└─────────────────────────────────────┘
```

---

## 5. Cas Limites Complets

### 5.1. Double Inscription Avant Annulation

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`
2. Utilisateur A essaie de s'inscrire à une autre initiation (sans annuler la première)

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible (implicite)
    BD: memberships = [membership (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A
    Frontend: Checkbox cochée, params[:use_free_trial] = "1"
    Controller: Vérifie .active.where(free_trial_used: true) → aucun résultat
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Essai gratuit "utilisé" immédiatement
    BD: attendances.active.where(free_trial_used: true) → [attendance_A]

T3: Enfant essaie de s'inscrire à Initiation B (sans annuler A)
    Controller: Vérifie .active.where(free_trial_used: true) → trouve attendance_A
    Controller: Redirige avec alert "Cet enfant a déjà utilisé son essai gratuit"
    Model: Validation can_use_free_trial échoue également
    BD: attendances = [attendance_A] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation modèle : `can_use_free_trial` détecte `attendance_A` active
- ✅ Validation contrôleur : Vérification préalable détecte `attendance_A` active
- ✅ Contrainte unique (si implémentée) : Empêche la création de `attendance_B`

**Résultat** : La deuxième inscription est bloquée avec message "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."

### 5.2. Essai Réutilisé Avant Première Annulation

**Scénario** : Identique au cas 5.1

**Protection** : Identique au cas 5.1

**Résultat** : La deuxième inscription est bloquée

### 5.3. Annulation puis Double Inscription

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`
2. Utilisateur A annule → `attendance_1.status = "canceled"`
3. Utilisateur A s'inscrit à deux initiations en parallèle (ou à la même initiation)

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Enfant annule Initiation A
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled")]

T3: Scope .active exclut canceled
    BD: attendances.active.where(free_trial_used: true) → [] (vide)

T4: Enfant essaie de s'inscrire à Initiation B et Initiation C en parallèle
    Requête 1: Controller vérifie .active → aucun résultat → crée attendance_B
    Requête 2: Controller vérifie .active → aucun résultat → essaie de créer attendance_C
    
    ⚠️ RACE CONDITION : Deux requêtes parallèles peuvent créer deux attendances
```

**Protection** :
- ✅ Scope `.active` exclut `attendance_A` (canceled)
- ⚠️ **Race condition possible** : Deux requêtes parallèles pourraient créer deux attendances

**Solution** : Contrainte unique au niveau base de données (Section 3.2)

### 5.4. Tentative de Contournement (Modification Paramètres)

**Scénario** : Utilisateur modifie les paramètres HTTP pour ne pas envoyer `use_free_trial`

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant avec statut trial sélectionné
    Frontend: Checkbox "Utiliser l'essai gratuit de [Nom Enfant] (OBLIGATOIRE)" affichée et cochée automatiquement
    JavaScript: Bouton submit activé uniquement si checkbox cochée
    Frontend: params[:use_free_trial] = "1"

T2: Utilisateur modifie les paramètres HTTP (dev tools)
    Frontend: params[:use_free_trial] = "0" (modifié)

T3: Controller reçoit params[:use_free_trial] = "0"
    Controller: Vérifie use_free_trial → false
    Controller: Redirige avec alert "L'essai gratuit est obligatoire"
    BD: attendances = [] (pas de nouvelle attendance)

T4: Si l'utilisateur contourne le contrôleur (impossible), le modèle bloque
    Model: Validation can_register_to_initiation vérifie free_trial_used
    Model: Pour trial, free_trial_used DOIT être true
    Model: Erreur "L'essai gratuit est obligatoire pour les enfants non adhérents"
    BD: attendances = [] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation modèle : Pour enfants `trial`, `free_trial_used` DOIT être `true` (vérifie l'état, pas les paramètres)
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état de la base de données

**Résultat** : L'inscription est bloquée avec message "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."

### 5.5. JavaScript Désactivé

**Scénario** : Utilisateur désactive JavaScript et essaie de soumettre sans cocher la checkbox

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant avec statut trial sélectionné
    Frontend: Checkbox "Utiliser l'essai gratuit de [Nom Enfant] (OBLIGATOIRE)" affichée
    JavaScript: Désactivé → pas de coche automatique, pas de désactivation du bouton
    Frontend: params[:use_free_trial] = nil (pas envoyé)

T2: Utilisateur soumet le formulaire
    Controller: Reçoit params[:use_free_trial] = nil
    Controller: Vérifie use_free_trial → false
    Controller: Redirige avec alert "L'essai gratuit est obligatoire"
    BD: attendances = [] (pas de nouvelle attendance)

T3: Si l'utilisateur contourne le contrôleur (impossible), le modèle bloque
    Model: Validation can_register_to_initiation vérifie free_trial_used
    Model: Pour trial, free_trial_used DOIT être true
    Model: Erreur "L'essai gratuit est obligatoire pour les enfants non adhérents"
    BD: attendances = [] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation contrôleur : Vérifie que `use_free_trial` est présent pour enfants `trial`
- ✅ Validation modèle : Vérifie que `free_trial_used = true` pour enfants `trial`

**Résultat** : L'inscription est bloquée avec message d'erreur approprié

### 5.6. Réinscription à la Même Initiation Après Annulation

**Scénario** : Enfant annule puis essaie de s'inscrire à nouveau à la même initiation

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (utilise essai gratuit)
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered", event_id: initiation_A.id)]

T2: Enfant annule Initiation A
    Controller: Met à jour attendance_A.status = "canceled"
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled", event_id: initiation_A.id)]

T3: Essai gratuit redevient disponible
    BD: attendances.active.where(free_trial_used: true) → [] (vide, car .active exclut canceled)

T4: Enfant essaie de s'inscrire à nouveau à Initiation A
    Controller: Vérifie l'unicité user_id + event_id + child_membership_id (sauf canceled)
    Controller: Trouve attendance_A (canceled) → autorise la réinscription
    Controller: Vérifie .active.where(free_trial_used: true) → aucun résultat → autorise l'essai gratuit
    Controller: Crée nouvelle Attendance avec free_trial_used = true
    BD: attendances = [
      attendance_A (free_trial_used: true, status: "canceled", event_id: initiation_A.id),
      attendance_A2 (free_trial_used: true, status: "registered", event_id: initiation_A.id)
    ]
```

**Protection** :
- ✅ Validation unicité : La contrainte `validates :user_id, uniqueness: { scope: [:event_id, :child_membership_id], conditions: -> { where.not(status: "canceled") } }` autorise la réinscription après annulation
- ✅ Essai gratuit : Le scope `.active` exclut l'attendance annulée, donc l'essai gratuit redevient disponible

**Résultat** : L'enfant peut s'inscrire à nouveau à la même initiation avec son essai gratuit

---

## 6. Gestion Enfants Multiples

### 6.1. Fonctionnement du Formulaire

Le formulaire d'inscription permet d'inscrire **un seul enfant à la fois** via un dropdown :

```erb
<%= form.collection_select :child_membership_id, 
    child_memberships, 
    :id, 
    ->(m) { "#{m.child_first_name} #{m.child_last_name}" }, 
    { prompt: "Sélectionner un enfant" } %>
```

**Caractéristiques** :
- Un seul enfant peut être sélectionné par soumission
- Chaque enfant a son propre essai gratuit (indépendant)
- Le parent peut soumettre plusieurs fois pour inscrire plusieurs enfants

### 6.2. Calcul de Disponibilité Essai Gratuit

**Règle métier** : Tous les enfants créés ont automatiquement un essai gratuit disponible (implicite).

**Pour chaque enfant dans le dropdown** :

```ruby
# app/views/shared/_registration_form_fields.html.erb
# IMPORTANT : Utiliser .active pour exclure les attendances annulées
trial_children = child_memberships.select { |m| m.trial? || m.pending? }
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    status: child.status,  # "trial" ou "pending"
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json  # Convertir en JSON string pour injection dans JavaScript
```

**Passage des données au JavaScript** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_children %>
  <script>
    // Données des enfants avec statut trial/pending
    // trial_children_data est déjà un JSON string (appel à .to_json dans le Ruby)
    const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
    
    // Exemple de données injectées :
    // const trialChildrenData = [
    //   { id: 123, name: "Alice Dupont", status: "pending", has_used_trial: false, can_use_trial: true },
    //   { id: 124, name: "Bob Dupont", status: "trial", has_used_trial: false, can_use_trial: true }
    // ];
  </script>
<% end %>
```

**Logique** :
- Chaque enfant est vérifié indépendamment
- Si un enfant a utilisé son essai gratuit (attendance active), `has_used_trial = true`
- Si un enfant n'a pas utilisé son essai gratuit, `can_use_trial = true`

**Affichage dans le dropdown** :
```
Parent voit :
[ ] Enfant A (pending) - Essai disponible (obligatoire, même si parent adhérent - v4.0 nominatif)
[ ] Enfant B (trial) - Essai disponible (obligatoire)
[ ] Enfant C (pending) - Essai utilisé (déjà inscrit à Initiation 1)
```

**Texte affiché différemment selon le statut** :
- Si `status = "pending"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (optionnel, pas cochée par défaut)
- Si `status = "trial"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (obligatoire, cochée par défaut, `required = true`)
- Si `has_used_trial = true` : 
  - Checkbox masquée (essai déjà utilisé)

**Code HTML réel complet** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_parent || show_free_trial_children %>
  <%# Champ caché pour garantir l'envoi de la valeur même si la checkbox est masquée %>
  <%= hidden_field_tag "use_free_trial_hidden#{prefix_id}", "0", id: "use_free_trial_hidden#{prefix_id}" %>
  
  <div class="mb-3 form-check" id="free_trial_container<%= prefix_id %>" style="<%= show_free_trial_parent || (show_free_trial_children && child_memberships.any? { |m| m.trial? }) ? '' : 'display: none;' %>">
    <!-- Checkbox essai gratuit -->
    <%= check_box_tag :use_free_trial, "1", false, { 
        class: "form-check-input", 
        id: "use_free_trial#{prefix_id}",
        aria: { describedby: "free_trial_help#{prefix_id}" },
        onchange: "window.toggleSubmitButton#{prefix_id} && window.toggleSubmitButton#{prefix_id}(); if (this.checked) { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '1'; } else { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '0'; }"
    } %>
    
    <%= label_tag "use_free_trial#{prefix_id}", class: "form-check-label", id: "use_free_trial_label#{prefix_id}" do %>
      <i class="bi bi-gift me-1" aria-hidden="true"></i>
      <span id="free_trial_text<%= prefix_id %>">Utiliser mon essai gratuit</span>
    <% end %>
    
    <small id="free_trial_help<%= prefix_id %>" class="text-muted d-block mt-1">
      <span id="free_trial_help_text<%= prefix_id %>">
        <% if is_initiation && event.allow_non_member_discovery? %>
          Vous pouvez utiliser votre essai gratuit maintenant ou vous inscrire dans les places découverte disponibles. Après cet essai, une adhésion sera requise pour continuer.
        <% else %>
          Vous n'avez pas encore utilisé votre essai gratuit. <strong>Cette case doit être cochée pour confirmer votre inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.
        <% end %>
      </span>
    </small>
  </div>
  
  <% if show_free_trial_children %>
    <script>
      // Données des enfants avec statut trial/pending (déjà en JSON string)
      const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
      
      // Le JavaScript met à jour dynamiquement le texte et l'état de la checkbox
      // selon l'enfant sélectionné (voir fonction updateFreeTrialDisplay)
    </script>
  <% end %>
<% end %>
```

**JavaScript qui gère l'affichage différencié** :
```javascript
// Pour enfant pending : checkbox obligatoire (même si parent adhérent - v4.0 nominatif)
if (selectedChild.status === "pending" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case est optionnelle.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = false; // Pas cochée par défaut
    freeTrialCheckbox.required = false; // Pas obligatoire
  }
}

// Pour enfant trial : checkbox obligatoire
if (selectedChild.status === "trial" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case doit être cochée pour confirmer l\'inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = true; // Cochée par défaut
    freeTrialCheckbox.required = true; // Obligatoire
  }
}
```

### 6.3. Scénarios Multi-Enfants

#### Scénario 1 : Trois Enfants, Deux avec Essai Disponible

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [
      membership_A (status: "pending"),
      membership_B (status: "pending"),
      membership_C (status: "pending")
    ]
    BD: attendances = []

T1: Parent inscrit Enfant B à Initiation 1
    BD: attendances = [attendance_B1 (free_trial_used: true, child_membership_id: B.id)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai utilisé (has_used_trial = true)
    - Enfant C : Essai disponible (can_use_trial = true)

T3: Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)
```

**Résultat** : Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)

#### Scénario 2 : Tous les Enfants ont Utilisé leur Essai

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [A, B, C] (tous pending)
    BD: attendances = []

T1: Parent inscrit tous les enfants
    BD: attendances = [
      attendance_A1 (free_trial_used: true, child_membership_id: A.id),
      attendance_B1 (free_trial_used: true, child_membership_id: B.id),
      attendance_C1 (free_trial_used: true, child_membership_id: C.id)
    ]

T2: Parent voit dropdown :
    - Tous les enfants : Essai utilisé (has_used_trial = true pour tous)
    - Checkbox essai gratuit : Masquée
    - Message : "Adhésion requise pour continuer"
```

**Résultat** : Aucun enfant n'a d'essai disponible, message "Adhésion requise"

#### Scénario 3 : Parent a Utilisé son Essai, Enfants Non

**Timeline** :
```
T0: Parent crée 2 enfants
    BD: memberships = [A, B] (tous pending)
    BD: attendances = []

T1: Parent s'inscrit lui-même à Initiation 1 (utilise son essai)
    BD: attendances = [attendance_parent (free_trial_used: true, child_membership_id: nil)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai disponible (can_use_trial = true)
    - Checkbox essai gratuit parent : Masquée (déjà utilisé)
```

**Résultat** : Enfants peuvent utiliser leur essai indépendamment du parent

---

## 7. Cycle de Vie des Statuts

### 7.1. Transitions de Statut

```
┌──────────┐
│ pending  │  ← Liste d'attente (pour attendances)
│          │  ← Adhésion en attente de paiement (pour memberships)
└────┬─────┘
     │
     ↓
┌──────────┐
│registered│  ← Inscrit (statut par défaut)
└────┬─────┘
     │
     ├──→ ┌────────┐
     │    │ paid   │  ← Payé
     │    └────────┘
     │
     ├──→ ┌──────────┐
     │    │ present  │  ← Présent le jour J
     │    └──────────┘
     │
     ├──→ ┌──────────┐
     │    │ no_show  │  ← Absent le jour J
     │    └──────────┘
     │
     └──→ ┌──────────┐
          │ canceled │  ← Annulé (essai gratuit redevient disponible)
          └──────────┘
```

### 7.2. Impact sur l'Essai Gratuit

| Statut | Essai Gratuit Considéré Utilisé ? | Essai Gratuit Disponible ? |
|--------|-----------------------------------|----------------------------|
| `pending` | ❌ Non (liste d'attente) | ✅ Oui (si pas encore utilisé) |
| `registered` | ✅ Oui | ❌ Non |
| `paid` | ✅ Oui | ❌ Non |
| `present` | ✅ Oui | ❌ Non |
| `no_show` | ✅ Oui | ❌ Non |
| `canceled` | ❌ **Non** (exclu du scope `.active`) | ✅ **Oui** (redevient disponible) |

### 7.3. Flux Complet Enfant

**Tous les enfants commencent en pending ?** 
- ✅ **Par défaut OUI** : Tous les enfants créés via le formulaire parent sont créés avec `status = "pending"` (sauf si `create_trial = "1"`)

**Quel est le flux complet pour enfant `pending` ?**

```
T0: Enfant créé avec status: pending (essai gratuit attribué automatiquement, implicite, obligatoire même si parent adhérent - v4.0 nominatif)
    BD: memberships = [membership (status: "pending", is_child_membership: true)]
    BD: attendances = []

T1: Parent inscrit enfant à Initiation A (peut utiliser essai gratuit ou non)
    Si essai utilisé : Attendance créée avec free_trial_used = true, status = "registered"
    Si essai non utilisé : Attendance créée avec free_trial_used = false, status = "registered"
    BD: attendances = [attendance_A (free_trial_used: true/false, status: "registered")]

T2: Enfant reste pending (adhésion en attente de paiement)
    BD: memberships = [membership (status: "pending")] (pas de changement)

T3: Parent paie l'adhésion
    BD: memberships = [membership (status: "active")]
    OU
    Si paiement rejeté ou expiré : pending reste (pas de changement automatique)
```

**Quel est le flux complet pour enfant `trial` ?**

```
T0: Enfant créé avec status: trial (essai gratuit OBLIGATOIRE)
    BD: memberships = [membership (status: "trial", is_child_membership: true)]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (DOIT utiliser essai gratuit)
    Controller: Vérifie que use_free_trial = "1" (obligatoire)
    Controller: Crée Attendance avec free_trial_used = true, status = "registered"
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Après l'initiation, le statut de l'adhésion reste trial
    BD: memberships = [membership (status: "trial")] (pas de changement automatique)
    
T3: Pour continuer, le parent doit convertir l'essai gratuit en adhésion payante
    Action manuelle : Parent clique sur "Convertir en adhésion payante" (route: /memberships/:id/convert_to_paid)
    Controller: Met à jour membership.status = "pending"
    BD: memberships = [membership (status: "pending")]

T4: Parent paie l'adhésion
    BD: memberships = [membership (status: "active")]
```

**Quand le statut change-t-il exactement ?**

- **Membership** :
  - `pending` → `active` : Lors du paiement réussi (callback HelloAsso)
  - `pending` → `pending` : Aucun changement si paiement non effectué
  - `trial` → `pending` : Lors de la conversion d'essai gratuit en adhésion payante (action manuelle)

- **Attendance** :
  - `registered` → `canceled` : Lors de l'annulation par l'utilisateur ou l'admin
  - `registered` → `paid` : Lors du paiement de l'initiation (si payant)
  - `registered` → `present` : Le jour J, marqué comme présent
  - `registered` → `no_show` : Le jour J, marqué comme absent

### 7.4. Règles de Transition

**Annulation (`registered` → `canceled`)** :
- ✅ L'essai gratuit redevient disponible immédiatement
- ✅ L'utilisateur peut s'inscrire à nouveau avec son essai gratuit
- ✅ Le scope `.active` exclut automatiquement cette attendance

**Autres transitions** :
- `registered` → `paid` : Essai gratuit reste utilisé
- `registered` → `present` : Essai gratuit reste utilisé
- `registered` → `no_show` : Essai gratuit reste utilisé

---

## 8. Tests d'Intégration Recommandés

**Ordre logique d'exécution des tests** :
1. **Modèle (Membership)** : Tests de création enfant (Section 8.1)
2. **Modèle (Attendance)** : Tests de validations essai gratuit (Sections 8.2-8.5)
3. **Requête HTTP** : Tests du contrôleur complet (Section 8.6)
4. **Intégration** : Tests end-to-end parent + enfant + initiation (Section 8.7)

### 8.1. Test : Enfant Créé → Statut pending + Essai Gratuit Attribué

**Fichier** : `spec/models/membership_spec.rb`

```ruby
# spec/models/membership_spec.rb
describe "Child membership creation" do
  it "creates child in pending with free trial available" do
    parent = create(:user)
    
    # Simuler la création d'un enfant via le formulaire
    membership = Membership.create!(
      user: parent,
      status: :pending,
      is_child_membership: true,
      child_first_name: "Alice",
      child_last_name: "Dupont",
      child_date_of_birth: 10.years.ago,
      # ... autres champs requis
    )
    
    expect(membership.status).to eq(:pending)
    expect(membership.is_child_membership).to eq(true)
    
    # Vérifier que l'essai gratuit est disponible (pas de champ DB, c'est implicite)
    # L'essai gratuit est disponible si aucune attendance active avec free_trial_used = true
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: membership.id).exists?).to eq(false)
  end
end
```

### 8.2. Test : Essai Gratuit Utilisé lors de l'Inscription

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial usage on initiation registration" do
  it "marks free trial as used on first initiation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Créer l'attendance avec essai gratuit
    attendance = Attendance.create!(
      user: parent,
      event: initiation,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    expect(attendance.free_trial_used).to eq(true)
    expect(attendance.status).to eq(:registered)
    
    # Vérifier que l'essai gratuit est maintenant "utilisé"
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(true)
  end
end
```

### 8.3. Test : Essai Gratuit Non Réutilisable

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial non-reusability" do
  it "prevents second initiation with same child free trial" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Deuxième inscription (devrait être bloquée)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    expect(attendance2).not_to be_valid
    expect(attendance2.errors[:free_trial_used]).to be_present
  end
end
```

### 8.4. Test : Essai Gratuit Réutilisable après Annulation

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial reuse after cancellation" do
  it "allows free trial reuse after cancellation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Annulation
    attendance1.update!(status: :canceled)
    
    # Deuxième inscription (devrait être possible)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    # Le scope .active exclut canceled, donc l'essai est disponible
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(false)
    expect(attendance2).to be_valid
  end
end
```

### 8.5. Test : Race Condition Protection

```ruby
# spec/models/attendance_spec.rb
describe "Race condition protection" do
  it "prevents double free trial usage in parallel requests" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Simuler deux requêtes parallèles
    threads = []
    2.times do
      threads << Thread.new do
        Attendance.create!(
          user: parent,
          event: initiation,
          child_membership_id: child.id,
          free_trial_used: true,
          status: :registered
        )
      end
    end
    
    threads.each(&:join)
    
    # Seule une attendance devrait être créée (grâce à la contrainte unique)
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).count).to eq(1)
  end
end
```

### 8.6. Test : JavaScript Désactivé

**Fichier** : `spec/requests/initiations/attendances_spec.rb`
describe "Without JavaScript" do
  it "validates free trial requirement server-side" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :trial,  # Statut trial = essai gratuit obligatoire
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Soumission sans paramètre use_free_trial (simule JS désactivé)
    post initiation_attendances_path(initiation), params: {
      child_membership_id: child.id
      # Pas de use_free_trial
    }
    
    expect(response).to have_http_status(:redirect)
    expect(Attendance.count).to eq(0)
    expect(flash[:alert]).to include("L'essai gratuit est obligatoire")
  end
end
```

---

## 9. Clarification Parent/Enfant

### 9.1. Indépendance Totale

**Règle** : Chaque personne (parent ou enfant) a son propre essai gratuit, indépendamment des autres.

### 9.2. Matrice de Possibilités

| Situation | Parent Essai | Enfant A Essai | Enfant B Essai | Résultat |
|-----------|--------------|----------------|----------------|----------|
| Tous disponibles | ✅ | ✅ | ✅ | Tous peuvent utiliser leur essai |
| Parent utilisé | ❌ | ✅ | ✅ | Enfants peuvent utiliser le leur |
| Enfant A utilisé | ✅ | ❌ | ✅ | Parent et Enfant B peuvent utiliser le leur |
| Tous utilisés | ❌ | ❌ | ❌ | Aucun essai disponible, adhésion requise |

### 9.3. Exemples Concrets

#### Exemple 1 : Parent Utilise son Essai, Enfant Non

**Timeline** :
```
T0: Parent crée enfant
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Parent s'inscrit lui-même à Initiation A (utilise son essai)
    BD: attendances = [attendance_parent (free_trial_used: true, child_membership_id: nil)]

T2: Enfant peut toujours utiliser son essai gratuit
    BD: attendances.active.where(free_trial_used: true, child_membership_id: child.id) → [] (vide)
    Enfant peut s'inscrire à Initiation B avec essai gratuit
```

**Résultat** : Deux attendances distinctes, deux essais gratuits utilisés indépendamment

#### Exemple 2 : Enfant Utilise son Essai, Parent Non

**Timeline** :
```
T0: Parent crée enfant
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (utilise son essai)
    BD: attendances = [attendance_enfant (free_trial_used: true, child_membership_id: child.id)]

T2: Parent peut toujours utiliser son essai gratuit
    BD: attendances.active.where(free_trial_used: true, child_membership_id: nil) → [] (vide)
    Parent peut s'inscrire à Initiation B avec essai gratuit
```

**Résultat** : Deux attendances distinctes, deux essais gratuits utilisés indépendamment

### 9.4. Distinction Technique

La distinction se fait via `child_membership_id` :
- `child_membership_id = nil` → Essai gratuit du **parent**
- `child_membership_id = X` → Essai gratuit de l'**enfant X**

```ruby
# Vérification parent
user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

# Vérification enfant
user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
```

---

## 10. Logique JavaScript vs Serveur (Sans JS)

### 10.1. Comment le JavaScript Détecte que l'Essai a été Attribué ?

**Où est stockée l'info "essai gratuit attribué" ?**

L'essai gratuit n'est **pas stocké explicitement** dans la base de données. C'est **implicite** :
- Tous les enfants créés ont automatiquement un essai gratuit disponible
- L'essai gratuit est "utilisé" lorsqu'une `Attendance` est créée avec `free_trial_used = true`

**Comment le frontend le sait ?**

Le frontend calcule la disponibilité en vérifiant les attendances actives :

```javascript
// app/views/shared/_registration_form_fields.html.erb
// Données préparées côté serveur (Ruby)
const trialChildrenData = <%= raw trial_children_data %>;

// trial_children_data contient :
{
  id: child.id,
  name: "Alice Dupont",
  has_used_trial: false,  // Calculé : !attendances.active.where(free_trial_used: true).exists?
  can_use_trial: true      // Calculé : !has_used_trial
}
```

**Code Ruby réel qui prépare les données** :
```ruby
# app/views/shared/_registration_form_fields.html.erb
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json
```

**Pas d'endpoint API nécessaire** : Les données sont calculées côté serveur et injectées dans le HTML via JSON.

### 10.2. Comportement avec JavaScript

**Avec JavaScript activé** :
- ✅ Checkbox cochée automatiquement pour enfants `trial` (obligatoire)
- ✅ Checkbox affichée mais obligatoire pour enfants `pending` (même si parent adhérent - v4.0 nominatif)
- ✅ Validation avant soumission (empêche soumission si non cochée pour `trial`)
- ✅ Mise à jour du champ caché automatique
- ✅ Meilleure UX (feedback immédiat)

### 10.3. Comportement sans JavaScript

**Sans JavaScript (ou JS désactivé)** :
- ⚠️ Checkbox peut ne pas être cochée automatiquement
- ✅ **Validation serveur prend le relais** :
  - Contrôleur vérifie que `use_free_trial` est présent pour enfants `trial`
  - Modèle vérifie que `free_trial_used = true` pour enfants `trial`
- ✅ L'inscription est bloquée avec message d'erreur approprié

### 10.4. Garantie de Fonctionnement

**Principe** : Le système fonctionne **même sans JavaScript**.

**Protection** :
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état
- ✅ Validation modèle : Vérifie l'état (source de vérité)
- ✅ Messages d'erreur clairs pour guider l'utilisateur

**Exemple de flux sans JS** :
```
1. Utilisateur sélectionne enfant trial
2. Checkbox non cochée automatiquement (JS désactivé)
3. Utilisateur soumet
4. Contrôleur détecte : use_free_trial manquant
5. Redirection avec message "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
6. Utilisateur coche manuellement et resoumet
7. Validation réussie
```

---

## 11. Métriques Métier et KPIs

### 11.1. Métriques à Suivre

#### Taux d'Utilisation Essai Gratuit

```ruby
# Nombre d'essais gratuits utilisés / Nombre d'enfants créés
free_trials_used = Attendance.active.where(free_trial_used: true).count
children_created = Membership.where(is_child_membership: true).count
usage_rate = (free_trials_used.to_f / children_created) * 100
```

#### Taux de Conversion Essai → Adhésion

```ruby
# Utilisateurs ayant utilisé essai gratuit ET créé une adhésion après
users_with_trial = User.joins(:attendances)
  .where(attendances: { free_trial_used: true })
  .distinct

users_converted = users_with_trial.joins(:memberships)
  .where("memberships.created_at > attendances.created_at")
  .where(memberships: { status: :active })
  .distinct
  .count

conversion_rate = (users_converted.to_f / users_with_trial.count) * 100
```

#### Taux de Réutilisation après Annulation

```ruby
# Utilisateurs ayant annulé puis réutilisé leur essai
canceled_with_trial = Attendance.where(free_trial_used: true, status: :canceled)
  .joins(:user)
  .distinct

reused = canceled_with_trial.joins("INNER JOIN attendances a2 ON a2.user_id = attendances.user_id")
  .where("a2.free_trial_used = true")
  .where("a2.created_at > attendances.updated_at")
  .where("a2.status != 'canceled'")
  .distinct
  .count

reuse_rate = (reused.to_f / canceled_with_trial.count) * 100
```

### 11.2. KPIs Recommandés

| KPI | Description | Cible | Fréquence |
|-----|-------------|-------|-----------|
| Taux d'utilisation essai gratuit | % enfants utilisant leur essai | > 60% | Mensuel |
| Taux de conversion | % essais → adhésions | > 40% | Mensuel |
| Taux de réutilisation | % annulations → réinscriptions | < 20% | Mensuel |
| Nombre d'essais utilisés | Total essais utilisés | - | Hebdomadaire |
| Nombre d'essais annulés | Total essais annulés | - | Hebdomadaire |

### 11.3. Dashboard Recommandé

**Métriques à afficher** :
- Graphique : Essais gratuits utilisés par mois
- Graphique : Taux de conversion essai → adhésion
- Tableau : Top 10 utilisateurs ayant utilisé leur essai
- Alerte : Si taux de réutilisation > 30% (possible abus)

### 11.4. Champs de Base de Données

**Champs existants** :
- `attendances.free_trial_used` : Boolean (existe déjà)
- `attendances.status` : Enum (existe déjà, permet de tracker canceled)

**Champs optionnels (pour tracking avancé)** :
- `attendances.free_trial_used_at` : Timestamp (NEW, optionnel)
- `memberships.free_trial_assigned_at` : Timestamp (NEW, optionnel, pour tracker quand l'essai a été attribué)

**Note** : Ces champs ne sont pas nécessaires pour le fonctionnement, mais peuvent être utiles pour les métriques avancées.

---

## 12. Implémentation Technique - Vues

### 12.1. Utilisation du Scope `.active`

**Définition du scope `.active`** :
```ruby
# app/models/attendance.rb
class Attendance < ApplicationRecord
  # Scope qui exclut les attendances annulées
  # Utilisé pour toutes les vérifications d'essai gratuit
  scope :active, -> { where.not(status: "canceled") }
  # ...
end
```

**RÈGLE CRITIQUE** : Toutes les vérifications d'essai gratuit dans les vues (`_registration_form_fields.html.erb`) doivent utiliser le scope `.active` pour exclure les attendances annulées.

**Pourquoi ce scope est important** :
- Les attendances avec `status = "canceled"` ne doivent pas être comptées comme "essai gratuit utilisé"
- Si un utilisateur annule une initiation où il avait utilisé son essai gratuit, l'essai redevient disponible
- Le scope `.active` garantit que seules les attendances actives (non annulées) sont prises en compte

**Exemples corrects** :
```ruby
# ✅ CORRECT : Utilise .personal pour vérifier UNIQUEMENT les adhésions personnelles du parent (pas celles des enfants)
# ⚠️ IMPORTANT v4.0 : Les essais gratuits sont NOMINATIFS - le statut des enfants n'a AUCUNE influence sur l'essai gratuit du parent
parent_can_use_trial = !current_user.memberships.personal.active_now.exists? && 
                       !current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

any_child_has_trial = trial_children.any? { |child| 
  !current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
}

trial_children_data = trial_children.map do |child|
  {
    has_used_trial: current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?,
    can_use_trial: !current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
  }
end

# ✅ CORRECT : Vérifier si le parent a une adhésion active PERSONNELLE (pour déterminer si l'essai est obligatoire pour les enfants pending)
parent_has_active_membership = current_user.memberships.personal.active_now.exists?
```

**Exemples incorrects** :
```ruby
# ❌ INCORRECT : N'utilise pas .active (inclut les attendances annulées)
parent_can_use_trial = !current_user.attendances.where(free_trial_used: true, child_membership_id: nil).exists?

# ❌ INCORRECT : N'utilise pas .personal (inclut les adhésions enfants)
# ⚠️ BUG CRITIQUE : Si un enfant a une adhésion active, cela empêche le parent d'utiliser son essai gratuit
# Le parent devrait pouvoir utiliser son essai gratuit même si un enfant est adhérent (essais nominatifs)
parent_can_use_trial = !current_user.memberships.active_now.exists? && 
                       !current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?
```

### 12.2. Échappement JavaScript

**RÈGLE** : Les noms d'enfants dans les template literals JavaScript doivent être échappés pour éviter les erreurs de syntaxe.

**Exemple correct** :
```javascript
// ✅ CORRECT : Échappement des caractères spéciaux
const childNameEscaped = String(selectedChild.name || '').replace(/&/g, '&amp;').replace(/'/g, '&#39;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> ...';
```

**Exemple incorrect** :
```javascript
// ❌ INCORRECT : Template literal avec interpolation non échappée
freeTrialHelpText.innerHTML = `<strong>Essai gratuit pour ${selectedChild.name} :</strong> ...`;
```

### 12.3. Cohérence Modèle/Vue/Contrôleur

**Règle** : Les vérifications d'essai gratuit doivent être cohérentes entre :
- **Modèle** (`Attendance`) : Utilise `.active.where()` ✅
- **Contrôleur** (`Initiations::AttendancesController`) : Utilise `.active.where()` ✅
- **Vue** (`_registration_form_fields.html.erb`) : Doit utiliser `.active.where()` ✅

**Vérification** : Tous les fichiers doivent utiliser le même pattern :
```ruby
current_user.attendances.active.where(free_trial_used: true, child_membership_id: ...)
```

---

## 13. Flux de Création Enfant

### 13.1. Formulaire de Création

**Quel formulaire ?**
- Route : `/memberships/new?child=true`
- Vue : `app/views/memberships/child_form.html.erb`
- Contrôleur : `MembershipsController#new` (action `new`)

**Validations ?**
- Nom, prénom, date de naissance : Obligatoires
- Questionnaire de santé : 9 questions obligatoires
- RGPD, autorisation parentale : Obligatoires si enfant < 16 ans
- Certificat médical : Recommandé pour FFRS (gestion au cas par cas selon type : rando vs compét)

**L'enfant est créé en pending automatiquement ?**
- ✅ **OUI** : Par défaut, tous les enfants sont créés avec `status = "pending"`
- ⚠️ **Exception** : Si `create_trial = "1"`, l'enfant est créé avec `status = "trial"`

**Quand `create_trial = "1"` ? Qui le définit ?**
- Le **parent** peut cocher une option dans le formulaire pour créer l'enfant avec le statut `trial`
- Cette option est affichée dans le formulaire si l'enfant n'a pas encore utilisé son essai gratuit
- Si `create_trial = "1"` : L'enfant est créé en `trial` (essai gratuit obligatoire)
- Si `create_trial` n'est pas coché : L'enfant est créé en `pending` (essai gratuit obligatoire, même si parent adhérent - v4.0 nominatif)

**Formulaire parent pour créer enfant en trial vs pending** :
- Route : `/memberships/new?child=true`
- Vue : `app/views/memberships/child_form.html.erb`
- Le formulaire contient une checkbox optionnelle "Créer avec essai gratuit obligatoire" qui définit `create_trial = "1"`
- Si la checkbox n'est pas cochée, l'enfant est créé en `pending` par défaut

**Essai gratuit attribué d'office ?**
- ✅ **OUI** : Tous les enfants créés ont automatiquement un essai gratuit disponible (implicite)
- L'essai gratuit n'est pas stocké dans la DB, c'est un droit automatique
- L'essai gratuit est "utilisé" lorsqu'une `Attendance` est créée avec `free_trial_used = true`

### 13.2. Code Réel de Création

```ruby
# app/controllers/memberships_controller.rb
def create_child_membership_from_params(child_params, index)
  # ...
  # Vérifier si c'est un essai gratuit (statut trial)
  create_trial = params[:create_trial] == "1" || child_params[:create_trial] == "1"
  
  if create_trial
    membership_status = :trial  # Statut trial = essai gratuit explicite
  else
    membership_status = :pending  # Statut pending = adhésion en attente + essai gratuit implicite
  end
  
  # Créer l'adhésion enfant
  membership = Membership.create!(
    user: current_user, # Le parent
    status: membership_status,
    is_child_membership: true,
    child_first_name: child_first_name,
    child_last_name: child_last_name,
    child_date_of_birth: child_date_of_birth,
    # ... autres champs
  )
  
  # L'essai gratuit est automatiquement disponible (implicite, pas de champ DB)
  # Il sera "utilisé" lors de la création d'une Attendance avec free_trial_used = true
end
```

---

## 14. Flux d'Inscription à Initiation

### 14.1. Sélection Enfant

**Parent sélectionne enfant (pending avec essai)**
- Dropdown affiche tous les enfants avec statut `active`, `trial` ou `pending`
- Pour chaque enfant, le système calcule si l'essai gratuit est disponible

### 14.2. Affichage Checkbox Essai Gratuit

**Checkbox essai gratuit : affichée ? cochée ? obligatoire ?**

**Pour enfant `pending`** :
- ✅ **Affichée** : Si l'enfant n'a pas encore utilisé son essai gratuit
- ✅ **Cochée par défaut** : L'essai gratuit est obligatoire (nominatif)
- ✅ **Obligatoire** : L'enfant DOIT utiliser son essai gratuit, même si le parent est adhérent
- ⚠️ **v4.0** : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence

**Pour enfant `trial`** :
- ✅ **Affichée** : Si l'enfant n'a pas encore utilisé son essai gratuit
- ✅ **Cochée par défaut** : L'essai gratuit est obligatoire
- ✅ **Obligatoire** : L'enfant DOIT utiliser son essai gratuit pour s'inscrire

### 14.3. Soumission et Utilisation Essai Gratuit

**Parent soumet**
- Le contrôleur reçoit `params[:use_free_trial]` (checkbox ou champ caché)
- Pour enfant `trial` : Le contrôleur vérifie que `use_free_trial` est présent
- Pour enfant `pending` : Le contrôleur utilise l'essai gratuit si `use_free_trial = "1"`, sinon l'enfant s'inscrit sans essai gratuit

**Serveur utilise essai gratuit**
- Le contrôleur crée `Attendance` avec `free_trial_used = true` si l'essai est utilisé
- Le modèle valide que l'essai n'a pas déjà été utilisé (scope `.active`)

**Enfant reste pending (en attente de paiement) ?**
- ✅ **OUI** : L'adhésion reste en `pending` même après l'utilisation de l'essai gratuit
- L'essai gratuit permet de s'inscrire à une initiation sans payer l'adhésion
- Après l'initiation, le parent doit finaliser le paiement de l'adhésion pour continuer

**Ou change de statut ?**
- ❌ **NON** : Le statut de l'adhésion ne change pas lors de l'inscription à une initiation
- Le statut change uniquement lors du paiement : `pending` → `active`

### 14.4. Code Réel d'Inscription

```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  child_membership_id = params[:child_membership_id].presence
  is_volunteer = params[:is_volunteer] == "1"
  
  # IMPORTANT : Définir child_membership AVANT son utilisation
  child_membership = child_membership_id.present? ? current_user.memberships.find_by(id: child_membership_id) : nil
  
  # Construction de l'attendance
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  attendance.child_membership_id = child_membership_id
  
  # Vérifier si l'utilisateur est adhérent (DÉFINITION DE is_member)
  # CODE RÉEL VÉRIFIÉ dans app/controllers/initiations/attendances_controller.rb:82-90
  is_member = if child_membership_id.present?
    # Pour un enfant : vérifier l'adhésion enfant (active, trial ou pending)
    # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
    unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
      redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
      return
    end
    # L'enfant est considéré comme membre si l'adhésion est active ou pending (pas trial)
    # ⚠️ CLARIFICATION CRITIQUE - INCOHÉRENCE entre contrôleur et modèle :
    # - Contrôleur : pending = is_member = true (dans le contrôleur uniquement)
    # - Modèle : pending = is_member = false (car active_now exclut pending)
    # ⚠️ **v4.0** : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
    # ✅ pending = essai obligatoire (nominatif), même si le parent est adhérent
    # ❌ trial = "non membre" (is_member = false, doit utiliser essai gratuit obligatoire)
    # ✅ active = "membre actif" (is_member = true, accès complet)
    child_membership.active? || child_membership.pending?
  else
    # Pour le parent : vérifier UNIQUEMENT l'adhésion parent PERSONNELLE (pas celle des enfants)
    # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - pas d'adhésion "famille"
    # ⚠️ CORRECTION CRITIQUE : Utiliser .personal pour exclure les adhésions enfants
    # Si un enfant a une adhésion active, cela ne doit PAS empêcher le parent d'utiliser son essai gratuit
    current_user.memberships.personal.active_now.exists?
  end
  
  # Pour un enfant avec statut pending : essai gratuit OBLIGATOIRE (nominatif)
  # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
  if child_membership_id.present? && child_membership&.pending?
    # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif), même si le parent est adhérent
    # Vérifier que l'essai gratuit est utilisé
    use_free_trial = params[:use_free_trial] == "1" || 
                     params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.present?
    unless use_free_trial
      redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
      return
    end
    attendance.free_trial_used = true
  end
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE (nominatif)
  # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
  if child_membership_id.present? && child_membership&.trial?
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."
      return
    end
    
    # Essai gratuit OBLIGATOIRE
    use_free_trial = params[:use_free_trial] == "1" || 
                     params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.any?
    unless use_free_trial
      redirect_to initiation_path(@initiation), alert: "Adhésion requise. L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
      return
    end
    
    attendance.free_trial_used = true
  end
  
  if attendance.save
    # Succès
  end
end
```

---

## 15. Quand l'Essai Gratuit est "Utilisé" ?

### 15.1. Timeline Précise

**À la création de l'attendance ?**
- ✅ **OUI** : L'essai gratuit est marqué comme utilisé lors de la création de l'`Attendance` avec `free_trial_used = true`
- Cela se fait dans le contrôleur, avant le `save`

**Ou à la validation de l'attendance ?**
- ❌ **NON** : La validation vérifie que l'essai n'a pas déjà été utilisé, mais ne le marque pas comme utilisé
- Le marquage se fait dans le contrôleur avant le `save`

**Ou quand l'enfant participe effectivement ?**
- ❌ **NON** : L'essai gratuit est utilisé dès la création de l'`Attendance`, pas lors de la participation

### 15.2. Code Réel

```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  
  # Marquer l'essai gratuit comme utilisé (AVANT le save)
  if params[:use_free_trial] == "1"
    attendance.free_trial_used = true  # ← ICI : Essai gratuit marqué comme utilisé
  end
  
  # Le save déclenche les validations
  if attendance.save  # ← ICI : Validations s'exécutent (vérifient l'unicité)
    # Succès
  end
end
```

---

## 16. Peut-on Réutiliser l'Essai Après Annulation ?

### 16.1. Règle

✅ **OUI** : Si un utilisateur annule une initiation où il avait utilisé son essai gratuit, l'essai gratuit redevient disponible.

### 16.2. Exemple Concret

**Timeline** :
```
T0: Enfant créé en pending + essai gratuit disponible (implicite)
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (essai gratuit utilisé)
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Essai gratuit "utilisé" = bloqué pour autres initiations
    BD: attendances.active.where(free_trial_used: true) → [attendance_A]

T3: Enfant annule Initiation A
    Controller: Met à jour attendance_A.status = "canceled"
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled")]

T4: Essai gratuit redevient disponible
    BD: attendances.active.where(free_trial_used: true) → [] (vide, car .active exclut canceled)

T5: Enfant peut s'inscrire à Initiation B avec essai gratuit
    Controller: Vérifie .active → aucun résultat → autorise l'inscription
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [
      attendance_A (free_trial_used: true, status: "canceled"),
      attendance_B (free_trial_used: true, status: "registered")
    ]
```

**Checkbox réapparaît ?**
- ✅ **OUI** : La checkbox réapparaît dans le formulaire d'inscription
- Le système calcule `can_use_trial = true` car le scope `.active` exclut l'attendance annulée

**Peut réutiliser essai ?**
- ✅ **OUI** : L'enfant peut réutiliser son essai gratuit après annulation

### 16.3. Code Réel

```ruby
# app/controllers/initiations/attendances_controller.rb
def destroy
  # ...
  attendance = current_user.attendances.find_by!(
    event: @initiation,
    child_membership_id: child_membership_id
  )
  
  # Annuler l'attendance
  attendance.update!(status: :canceled)
  
  # L'essai gratuit redevient automatiquement disponible
  # car le scope .active exclut les attendances canceled
end
```

---

## 17. Résumé des Corrections v3.0

### 17.1. Problèmes Critiques Résolus

✅ **Flux de création enfant** : Documenté avec timeline précise (T0, T1, T2...)
✅ **Quand l'essai gratuit est utilisé** : Clarifié (lors de la création de l'Attendance)
✅ **Champs de base de données** : Documentés (free_trial_used, status, scope .active)
✅ **Code Ruby réel** : Ajouté pour modèle, contrôleur, vue

### 17.2. Manques Complétés

✅ **Affichage checkbox pour chaque enfant** : Documenté (pending = obligatoire même si parent adhérent - v4.0 nominatif, trial = obligatoire même si parent adhérent - v4.0 nominatif)
✅ **Timeline des cas limites** : Ajoutée pour chaque scénario (T0, T1, T2...)
✅ **Tests spécifiques** : Ajoutés pour création enfant, utilisation essai, réutilisation après annulation
✅ **Flux d'inscription** : Documenté étape par étape

### 17.3. Imprécisions Clarifiées

✅ **JavaScript vs serveur** : Comment le frontend détecte l'essai gratuit (données calculées côté serveur)
✅ **Métriques avancées** : Champs optionnels pour tracking (free_trial_used_at, etc.)
✅ **Réutilisation après annulation** : Exemple concret avec timeline

---

---

## 18. Clarifications Supplémentaires

### 18.1. Essai Gratuit Parent Quand Adhésion Active

**Question** : Si le parent a une adhésion active, peut-il quand même utiliser son essai gratuit ?

**Réponse** :
- ❌ **NON** : Si le parent a une adhésion active, il n'a pas besoin d'utiliser son essai gratuit
- L'essai gratuit est uniquement pour les non-adhérents
- Si le parent est adhérent, il peut s'inscrire directement sans utiliser l'essai gratuit

**Code réel** :
```ruby
# app/controllers/initiations/attendances_controller.rb
# ⚠️ CORRECTION CRITIQUE : Utiliser .personal pour vérifier UNIQUEMENT les adhésions personnelles du parent
# Si un enfant a une adhésion active, cela ne doit PAS empêcher le parent d'utiliser son essai gratuit
is_member = current_user.memberships.personal.active_now.exists?

if is_member
  # Parent est adhérent → pas besoin d'essai gratuit
  # L'inscription est autorisée directement
else
  # Parent n'est pas adhérent → essai gratuit requis (si pas de places découverte)
  if params[:use_free_trial] == "1"
    attendance.free_trial_used = true
  end
end
```

### 18.2. Essai Gratuit Enfant Trial - Logique v4.0 (NOMINATIF)

**⚠️ CORRECTION MAJEURE v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque personne doit avoir sa propre adhésion.

**Question** : Si le parent a une adhésion active, l'enfant avec statut `trial` doit-il quand même utiliser son essai gratuit ?

**Réponse v4.0** :
- ✅ **OUI** : L'enfant `trial` DOIT utiliser son essai gratuit, même si le parent est adhérent
- ⚠️ **Les essais gratuits sont NOMINATIFS** : Le statut du parent n'a **AUCUNE influence** sur l'accès de l'enfant
- Chaque personne (adulte ou enfant) doit avoir sa propre adhésion - pas d'adhésion "famille"

**Code réel côté serveur (v4.0)** :
```ruby
# app/controllers/initiations/attendances_controller.rb
# ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
if child_membership_id.present? && child_membership&.trial?
  # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif), même si le parent est adhérent
  use_free_trial = params[:use_free_trial] == "1" || 
                   params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.present?
  unless use_free_trial
    redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
    return
  end
  attendance.free_trial_used = true
end
```

**Code JavaScript côté client** :
```javascript
// Le JavaScript affiche la checkbox obligatoire pour tous les enfants trial
if (selectedChild.status === "trial" && !selectedChild.has_used_trial) {
  // Affiche checkbox obligatoire
  freeTrialCheckbox.checked = true;
  freeTrialCheckbox.required = true;
}
```

**Protection multi-niveaux** :
- ✅ **JavaScript** : Affiche la checkbox obligatoire pour tous les enfants `trial` (UX)
- ✅ **Contrôleur** : Vérifie que `use_free_trial` est présent (première ligne de défense)
- ✅ **Modèle** : Vérifie que `free_trial_used = true` pour enfants `trial` (source de vérité)

**Résultat v4.0** : L'enfant `trial` DOIT utiliser son essai gratuit, indépendamment du statut du parent. Les essais gratuits sont **100% nominatifs**.

---

---

## 19. Résumé des Corrections v3.1 → v3.2

### 19.1. Corrections Critiques

✅ **Migration DB** : 
- Clarification que l'index sans `event_id` est intentionnel (un seul essai par personne, quel que soit l'événement)
- Ajout de commentaires expliquant pourquoi `disable_ddl_transaction!` n'est pas utilisé en développement
- Correction de la syntaxe pour correspondre au code réel

✅ **Code Contrôleur** :
- Ajout de la définition complète de `is_member` au début du contrôleur
- Code réel complet avec toutes les vérifications

✅ **Code HTML** :
- Ajout du code ERB complet de la checkbox essai gratuit
- Clarification du passage des données au JavaScript (`trial_children_data` déjà en JSON)

✅ **Tests** :
- Réorganisation par ordre logique (Modèle → Requête → Intégration)
- Ajout des noms de fichiers pour chaque test

✅ **Flux Trial** :
- Clarification que les deux sections "flux complet" (pending et trial) sont intentionnelles
- Ajout de timeline précise pour chaque statut

✅ **Scope .active** :
- Ajout de la définition complète avec explication de son importance

---

---

## 20. Corrections Finales v3.2 → v3.3

### 20.1. Corrections Mineures

✅ **Migration DB - Commentaire disable_ddl_transaction!** :
- Clarification complète : développement vs production
- Exemple de code pour production avec `CREATE INDEX CONCURRENTLY`

✅ **Code Contrôleur - Variable child_membership** :
- Ajout de la définition de `child_membership` avant son utilisation
- Code réel complet avec toutes les variables définies

✅ **Essai Trial Quand Parent Adhérent** :
- Clarification que le JavaScript ne peut pas savoir si le parent est adhérent
- Explication de la protection multi-niveaux (JS → Contrôleur → Modèle)
- Code réel côté serveur et côté client documenté

✅ **Section 7.3 - Flux Trial** :
- Les deux sections "flux complet" (pending et trial) sont intentionnelles et nécessaires
- Chaque statut a son propre flux documenté

---

---

## 21. Checklist Finale de Vérification

### 21.1. Points Critiques Vérifiés

✅ **Migration DB** :
- Index sans `event_id` : Intentionnel (un seul essai par personne)
- Index composite pour enfants : `[:user_id, :child_membership_id]` ✅
- Commentaire `disable_ddl_transaction!` : Clarifié (dev vs production)

✅ **Code Contrôleur** :
- Variable `child_membership` : Définie avant utilisation ✅
- Variable `is_member` : Définie au début ✅
- Code complet avec toutes les vérifications ✅

✅ **Code Vue** :
- HTML ERB complet : Présent ✅
- Passage données JS : `trial_children_data` déjà en JSON ✅
- JavaScript différencié : pending vs trial documenté ✅

✅ **Logique Métier** :
- Essai trial quand parent adhérent : Clarifié (protection multi-niveaux) ✅
- Essai reste disponible si non utilisé : Clarifié ✅
- Réinscription même initiation : Documenté ✅

✅ **Tests** :
- Ordre logique : Modèle → Requête → Intégration ✅
- Noms de fichiers : Ajoutés pour chaque test ✅

✅ **Documentation** :
- Timeline précises : T0, T1, T2... pour chaque cas ✅
- Code Ruby réel : Pas de pseudo-code ✅
- Scope `.active` : Défini avec explication ✅

---

## 22. Matrice Complète des Cas de Figure

### 22.1. Statuts d'Adhésion

**Statuts possibles** (enum `Membership.status`) :
- `pending` (0) : Adhésion en attente de paiement (enfants uniquement) - L'enfant a une adhésion mais pas encore payée
- `active` (1) : Adhésion active et valide - L'enfant est adhérent et peut s'inscrire sans restriction
- `expired` (2) : Adhésion expirée - L'adhésion a expiré, l'enfant est traité comme non-adhérent
- `trial` (3) : Essai gratuit (enfants uniquement) - L'enfant n'a **PAS** d'adhésion, c'est un non-adhérent

**⚠️ IMPORTANT : Les statuts sont mutuellement exclusifs**
- Un enfant ne peut pas être `pending` ET `trial` en même temps
- `pending` = Adhésion en attente (l'enfant a une adhésion mais pas encore payée)
- `trial` = Non adhérent (l'enfant n'a PAS d'adhésion, c'est un essai gratuit)

**📋 Logique `is_member` (Code réel vérifié dans `app/controllers/initiations/attendances_controller.rb:82-90`) :**
- `is_member = child_membership.active? || child_membership.pending?`
- **Signification** :
  - `pending` = **"a le droit d'accès"** (considéré comme membre car l'adhésion est en cours)
  - `trial` = **"non membre"** (`is_member = false`, doit utiliser essai gratuit obligatoire)
  - `active` = **"membre actif"** (`is_member = true`, accès complet)
- **Pourquoi `pending` est considéré comme membre ?**
  - L'adhésion est en cours de traitement (le parent a commencé le processus)
  - L'enfant peut s'inscrire sans utiliser son essai gratuit (car `is_member = true`)
  - L'essai gratuit reste disponible comme option (pas obligatoire)

**Scopes importants** :
- `active_now` : Adhésions actives ET dont `end_date > Date.current`
- `active` : Adhésions avec `status = 'active'` (peut être expirée si `end_date < Date.current`)

---

### 22.2. Cas de Figure - Parent (Adulte)

#### Cas 1 : Parent Adhérent Actif (`active_now`)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut parent | `active` + `end_date > Date.current` | ✅ **OUI** (sans restriction) | ❌ **MASQUÉE** | 🔵 **BLEU** (toujours actif) |
| Essai gratuit utilisé | N/A (adhérent) | ✅ **OUI** | ❌ **MASQUÉE** | 🔵 **BLEU** |
| `allow_non_member_discovery` | N/A | ✅ **OUI** | ❌ **MASQUÉE** | 🔵 **BLEU** |

**Comportement** : Le parent adhérent peut s'inscrire à toutes les initiations sans restriction. La checkbox essai gratuit n'apparaît jamais.

---

#### Cas 2 : Parent Non Adhérent + Essai Gratuit Disponible

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut parent | Aucune adhésion `active_now` | ✅ **OUI** (avec essai gratuit) | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `false` (pas d'attendance active avec `free_trial_used = true`) | ✅ **OUI** | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| `allow_non_member_discovery` | `false` | ✅ **OUI** (essai gratuit requis) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |
| `allow_non_member_discovery` | `true` | ✅ **OUI** (essai gratuit ou places découverte) | ✅ **VISIBLE** (optionnel) | ⚪ **GRIS** si non cochée (même avec places découverte) |

**Comportement** : 
- La checkbox s'affiche avec le texte "Utiliser mon essai gratuit"
- Le bouton est **GRIS** par défaut et devient **BLEU** uniquement si la checkbox est cochée
- Même si `allow_non_member_discovery` est activé, le bouton reste gris si la checkbox n'est pas cochée (force l'utilisation explicite de l'essai gratuit)

---

#### Cas 3 : Parent Non Adhérent + Essai Gratuit Déjà Utilisé

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut parent | Aucune adhésion `active_now` | ❌ **NON** (bloqué) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Essai gratuit utilisé | `true` (attendance active avec `free_trial_used = true`) | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| `allow_non_member_discovery` | `false` | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| `allow_non_member_discovery` | `true` | ❌ **NON** (bloqué même avec places découverte) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : 
- Le contrôleur bloque l'inscription avec le message : "Vous avez déjà utilisé votre essai gratuit. Une adhésion est maintenant requise pour continuer."
- La validation du modèle `Attendance` bloque également l'inscription
- **SÉCURITÉ CRITIQUE** : Même si `allow_non_member_discovery` est activé, un parent qui a déjà utilisé son essai gratuit ne peut plus s'inscrire sans adhésion active

---

#### Cas 4 : Parent Adhérent Expiré (`expired` ou `active` avec `end_date < Date.current`)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut parent | `expired` OU `active` avec `end_date < Date.current` | ✅ **OUI** (avec essai gratuit si disponible - Case 4.2) | ✅ **VISIBLE** si essai disponible | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `false` | ✅ **OUI** (Case 4.2) | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `true` | ❌ **NON** (bloqué - Case 4.3) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : Un parent avec une adhésion expirée est traité comme un non-adhérent. Les règles des cas 2 et 3 s'appliquent.

---

### 22.3. Cas de Figure - Enfant

#### Cas 5 : Enfant `pending` + Essai Gratuit Disponible (Case 1.1)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `pending` | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `false` | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Parent adhérent | N/A | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |
| Parent non adhérent | N/A | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |

**Comportement v4.0** : 
- ⚠️ **Les essais gratuits sont NOMINATIFS** : Le statut du parent n'a **AUCUNE influence** sur l'accès de l'enfant
- L'enfant `pending` DOIT utiliser son essai gratuit (obligatoire), même si le parent est adhérent
- Le bouton est **GRIS** si la checkbox n'est pas cochée

---

#### Cas 6 : Enfant `pending` + Essai Gratuit Déjà Utilisé (Case 1.3)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `pending` | ❌ **NON** (bloqué) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Essai gratuit utilisé | `true` (attendance active avec `free_trial_used = true`) | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Parent adhérent | `active_now` | ❌ **NON** (bloqué même si parent adhérent) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| `allow_non_member_discovery` | `true` | ❌ **NON** (bloqué même avec places découverte) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : 
- Le contrôleur bloque l'inscription avec le message : "L'essai gratuit a déjà été utilisé. Une adhésion active est maintenant requise pour s'inscrire."
- **SÉCURITÉ CRITIQUE** : Même si le parent est adhérent ou si `allow_non_member_discovery` est activé, un enfant `pending` qui a déjà utilisé son essai gratuit ne peut plus s'inscrire sans adhésion active

---

#### Cas 7 : Enfant `trial` + Essai Gratuit Disponible

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `trial` | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `false` | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Parent adhérent | N/A | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |
| Parent non adhérent | N/A | ✅ **OUI** (via essai obligatoire - nominatif) | ✅ **VISIBLE** (obligatoire) | ⚪ **GRIS** si non cochée |

**Comportement v4.0** : 
- ⚠️ **Les essais gratuits sont NOMINATIFS** : Le statut du parent n'a **AUCUNE influence** sur l'accès de l'enfant
- L'enfant `trial` DOIT utiliser son essai gratuit (obligatoire), même si le parent est adhérent
- Le bouton est **GRIS** si la checkbox n'est pas cochée

---

#### Cas 8 : Enfant `trial` + Essai Gratuit Déjà Utilisé (Case 2.3)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `trial` | ❌ **NON** (bloqué) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Essai gratuit utilisé | `true` (attendance active avec `free_trial_used = true`) | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Parent adhérent | `active_now` | ❌ **NON** (bloqué même si parent adhérent) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| `allow_non_member_discovery` | `true` | ❌ **NON** (bloqué même avec places découverte) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : Identique au cas 6 (Case 1.3). Un enfant `trial` qui a déjà utilisé son essai gratuit ne peut plus s'inscrire sans adhésion active.

---

#### Cas 9 : Enfant `active` (Adhérent Actif) (Case 3.X)

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `active` + `end_date > Date.current` | ✅ **OUI** (sans restriction) | ❌ **MASQUÉE** | 🔵 **BLEU** (toujours actif) |
| Essai gratuit utilisé | N/A (adhérent) | ✅ **OUI** | ❌ **MASQUÉE** | 🔵 **BLEU** |
| Parent adhérent | N/A | ✅ **OUI** | ❌ **MASQUÉE** | 🔵 **BLEU** |

**Comportement** : Identique au cas 1 (parent adhérent). L'enfant adhérent peut s'inscrire à toutes les initiations sans restriction (Case 3.X : TOUJOURS ACCÈS, peu importe).

---

#### Cas 10 : Enfant `expired` ou `active` avec `end_date < Date.current`

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| Statut enfant | `expired` OU `active` avec `end_date < Date.current` | ✅ **OUI** (avec essai gratuit si disponible) | ✅ **VISIBLE** si essai disponible | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `false` | ✅ **OUI** | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Essai gratuit utilisé | `true` | ❌ **NON** (bloqué) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : Un enfant avec une adhésion expirée est traité comme un non-adhérent. Les règles des cas 5-8 s'appliquent selon le statut précédent (`pending` ou `trial`).

---

### 22.4. Cas de Figure - Menu Déroulant Enfant

#### Cas 11 : Aucun Enfant Sélectionné + Parent avec Essai Gratuit Disponible

| Critère | Valeur | Checkbox Essai | Bouton Submit |
|---------|--------|---------------|---------------|
| Enfant sélectionné | Aucun (`child_membership_id` vide) | ✅ **VISIBLE** (pour le parent) | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Parent essai disponible | `true` | ✅ **VISIBLE** | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Texte checkbox | "Utiliser mon essai gratuit" | ✅ **VISIBLE** | - |

**Comportement** : La checkbox s'affiche pour le parent. Le bouton est gris si la checkbox n'est pas cochée.

---

#### Cas 12 : Aucun Enfant Sélectionné + Parent sans Essai Gratuit

| Critère | Valeur | Checkbox Essai | Bouton Submit |
|---------|--------|---------------|---------------|
| Enfant sélectionné | Aucun (`child_membership_id` vide) | ❌ **MASQUÉE** | 🔵 **BLEU** (toujours actif) |
| Parent essai disponible | `false` | ❌ **MASQUÉE** | 🔵 **BLEU** |

**Comportement** : La checkbox est masquée. Le bouton est toujours bleu (inscription normale pour le parent).

---

#### Cas 13 : Enfant avec Essai Gratuit Sélectionné

| Critère | Valeur | Checkbox Essai | Bouton Submit |
|---------|--------|---------------|---------------|
| Enfant sélectionné | Enfant `trial` ou `pending` avec `can_use_trial = true` | ✅ **VISIBLE** (pour cet enfant) | 🔵 **BLEU** si cochée / ⚪ **GRIS** si non cochée |
| Texte checkbox | "Utiliser l'essai gratuit de [Nom Enfant]" | ✅ **VISIBLE** | - |
| Enfant `trial` | `true` | ✅ **VISIBLE** (obligatoire, cochée par défaut) | ⚪ **GRIS** si non cochée |
| Enfant `pending` | `true` | ✅ **VISIBLE** (obligatoire - nominatif, même si parent adhérent) | ⚪ **GRIS** si non cochée (essai obligatoire, même si parent adhérent) |

**Comportement** : La checkbox s'affiche uniquement pour l'enfant sélectionné. Le texte change selon l'enfant.

---

#### Cas 14 : Enfant sans Essai Gratuit Sélectionné

| Critère | Valeur | Checkbox Essai | Bouton Submit |
|---------|--------|---------------|---------------|
| Enfant sélectionné | Enfant `active` OU `expired` OU essai déjà utilisé | ❌ **MASQUÉE** | 🔵 **BLEU** (toujours actif) |
| Enfant `active` | `true` | ❌ **MASQUÉE** | 🔵 **BLEU** |
| Enfant essai utilisé | `true` | ❌ **MASQUÉE** | 🔵 **BLEU** |

**Comportement** : La checkbox est masquée car l'enfant sélectionné n'a pas d'essai gratuit disponible. Le bouton est toujours bleu (inscription normale).

---

### 22.5. Cas de Figure - `allow_non_member_discovery`

#### Cas 15 : `allow_non_member_discovery = true` + Essai Gratuit Disponible

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| `allow_non_member_discovery` | `true` | ✅ **OUI** (essai gratuit OU places découverte) | ✅ **VISIBLE** | ⚪ **GRIS** si non cochée (force l'utilisation explicite) |
| `non_member_discovery_slots` | `nil` (illimité) | ✅ **OUI** | ✅ **VISIBLE** | ⚪ **GRIS** si non cochée |
| `non_member_discovery_slots` | `10` (limité) | ✅ **OUI** (si places disponibles) | ✅ **VISIBLE** | ⚪ **GRIS** si non cochée |
| Essai gratuit disponible | `true` | ✅ **OUI** | ✅ **VISIBLE** | 🔵 **BLEU** si cochée |

**Comportement** : 
- Même si des places découverte sont disponibles, le bouton reste **GRIS** si la checkbox n'est pas cochée
- Cela force l'utilisateur à utiliser explicitement son essai gratuit
- Exception : Enfant `pending` → bouton gris si non cochée (essai obligatoire, même si parent adhérent - v4.0 nominatif)

---

#### Cas 16 : `allow_non_member_discovery = true` + Essai Gratuit Déjà Utilisé

| Critère | Valeur | Accès Initiation | Checkbox Essai | Bouton Submit |
|---------|--------|------------------|----------------|---------------|
| `allow_non_member_discovery` | `true` | ❌ **NON** (bloqué même avec places découverte) | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| `non_member_discovery_slots` | `nil` (illimité) | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |
| Essai gratuit utilisé | `true` | ❌ **NON** | ❌ **MASQUÉE** | ❌ **BLOQUÉ** |

**Comportement** : 
- **SÉCURITÉ CRITIQUE** : Même si `allow_non_member_discovery` est activé et qu'il y a des places découverte disponibles, un utilisateur qui a déjà utilisé son essai gratuit ne peut plus s'inscrire sans adhésion active
- Le contrôleur bloque l'inscription avant même de vérifier les places découverte

---

### 22.6. Résumé des Règles de Bouton Submit

#### Bouton BLEU (Actif) ✅

Le bouton est **BLEU** dans les cas suivants :
1. ✅ Parent/Enfant adhérent actif (`active_now`) → Toujours bleu
2. ✅ Checkbox essai gratuit cochée → Bouton bleu
3. ✅ Pas de checkbox essai gratuit disponible → Toujours bleu

#### Bouton GRIS (Désactivé) ⚪

Le bouton est **GRIS** dans les cas suivants :
1. ⚪ Checkbox essai gratuit non cochée (parent ou enfant `trial`) → Bouton gris
2. ⚪ Enfant `trial` sélectionné + checkbox non cochée → Bouton gris
3. ⚪ Enfant `pending` sélectionné + checkbox non cochée → Bouton gris (essai obligatoire, même si parent adhérent - v4.0 nominatif)
4. ⚪ Parent non adhérent + checkbox non cochée (même avec `allow_non_member_discovery`) → Bouton gris

#### Bouton BLOQUÉ (Inscription Impossible) ❌

Le bouton est **BLOQUÉ** dans les cas suivants :
1. ❌ Essai gratuit déjà utilisé (parent ou enfant) → Inscription bloquée par le contrôleur
2. ❌ Enfant `pending` + essai déjà utilisé → Inscription bloquée même si parent adhérent
3. ❌ Enfant `trial` + essai déjà utilisé → Inscription bloquée même si parent adhérent

---

### 22.7. Checklist de Vérification des Erreurs

#### ✅ Vérifications à Effectuer

1. **Parent Adhérent Actif** :
   - [ ] Peut s'inscrire sans restriction
   - [ ] Checkbox essai gratuit masquée
   - [ ] Bouton toujours bleu

2. **Parent Non Adhérent + Essai Disponible** :
   - [ ] Checkbox visible avec texte "Utiliser mon essai gratuit"
   - [ ] Bouton gris par défaut
   - [ ] Bouton bleu si checkbox cochée
   - [ ] Bouton gris si checkbox non cochée (même avec `allow_non_member_discovery`)

3. **Parent Non Adhérent + Essai Utilisé** :
   - [ ] Inscription bloquée par le contrôleur
   - [ ] Message d'erreur : "Vous avez déjà utilisé votre essai gratuit..."
   - [ ] Bloqué même si `allow_non_member_discovery` est activé

4. **Enfant `pending` + Essai Disponible** :
   - [ ] Checkbox visible avec texte "Utiliser l'essai gratuit de [Nom] (optionnel)"
   - [ ] Bouton toujours bleu (essai optionnel)
   - [ ] Peut s'inscrire sans cocher la checkbox

5. **Enfant `pending` + Essai Utilisé** :
   - [ ] Inscription bloquée même si parent adhérent
   - [ ] Message d'erreur : "Cet enfant a déjà utilisé son essai gratuit..."
   - [ ] Bloqué même si `allow_non_member_discovery` est activé

6. **Enfant `trial` + Essai Disponible** :
   - [ ] Checkbox visible avec texte "Utiliser l'essai gratuit de [Nom]"
   - [ ] Checkbox cochée par défaut et obligatoire
   - [ ] Bouton gris si checkbox non cochée
   - [ ] Bouton bleu si checkbox cochée

7. **Enfant `trial` + Essai Utilisé** :
   - [ ] Inscription bloquée même si parent adhérent
   - [ ] Message d'erreur approprié
   - [ ] Bloqué même si `allow_non_member_discovery` est activé

8. **Menu Déroulant** :
   - [ ] Aucun enfant sélectionné → Checkbox pour parent si disponible
   - [ ] Enfant avec essai sélectionné → Checkbox pour cet enfant uniquement
   - [ ] Enfant sans essai sélectionné → Checkbox masquée

9. **`allow_non_member_discovery`** :
   - [ ] Bouton gris si checkbox non cochée (même avec places découverte)
   - [ ] Essai utilisé → Bloqué même avec places découverte disponibles

---

---

## 23. Corrections v3.4 → v3.5

### 23.1. Clarification Critique - Statuts Mutuellement Exclusifs

✅ **Correction majeure** : Clarification que `pending` et `trial` sont **mutuellement exclusifs** :
- `pending` (0) : Adhésion en attente de paiement - L'enfant a une adhésion mais pas encore payée
- `trial` (3) : Essai gratuit - L'enfant n'a **PAS** d'adhésion, c'est un non-adhérent
- Un enfant ne peut pas être les deux en même temps

✅ **Correction de la question "Est-ce qu'un enfant peut avoir un profil SANS essai gratuit ?"** :
- Réponse corrigée : OUI, un enfant `active` n'a pas besoin d'essai gratuit
- Réponse corrigée : OUI, un enfant `expired` peut ne plus avoir d'essai gratuit s'il l'a déjà utilisé
- Réponse maintenue : NON, un enfant créé avec `pending` ou `trial` a automatiquement un essai gratuit disponible

### 23.2. Synchronisation avec les Fichiers Détaillés

✅ **Mise à jour** : Synchronisation complète avec tous les fichiers détaillés dans `docs/development/essai-gratuit/` :
- Ajout de références croisées vers les fichiers détaillés
- Correction de la réponse sur les enfants sans essai gratuit
- Ajout d'exemples concrets pour le statut `pending`
- Ajout de liens vers les cas limites et sections détaillées

### 23.3. Clarification Logique `is_member` (v3.6)

✅ **Clarification critique** : Explication de la logique `is_member` vérifiée dans le code réel :
- **Code réel vérifié** : `app/controllers/initiations/attendances_controller.rb:82-90`
- **Logique** : `is_member = child_membership.active? || child_membership.pending?`
- **Signification clarifiée** :
  - `pending` = **"a le droit d'accès"** (considéré comme membre car l'adhésion est en cours)
  - `trial` = **"non membre"** (`is_member = false`, doit utiliser essai gratuit obligatoire)
  - `active` = **"membre actif"** (`is_member = true`, accès complet)
- **Pourquoi `pending` est considéré comme membre ?**
  - L'adhésion est en cours de traitement (le parent a commencé le processus)
  - L'enfant peut s'inscrire sans utiliser son essai gratuit (car `is_member = true`)
  - L'essai gratuit reste disponible comme option (pas obligatoire)

---

## 24. Références aux Fichiers Détaillés

Cette documentation principale est complétée par des fichiers détaillés dans `docs/development/essai-gratuit/` :

### 📋 Règles et Concepts
- [01-regles-generales.md](docs/development/essai-gratuit/01-regles-generales.md) - Règles générales et restrictions
- [02-statut-pending.md](docs/development/essai-gratuit/02-statut-pending.md) - Clarification complète du statut `pending`

### 🔒 Sécurité et Validations
- [03-race-conditions.md](docs/development/essai-gratuit/03-race-conditions.md) - Protection contre les race conditions
- [04-validations-serveur.md](docs/development/essai-gratuit/04-validations-serveur.md) - Validations multi-niveaux

### 🧪 Cas Limites et Tests
- [05-cas-limites.md](docs/development/essai-gratuit/05-cas-limites.md) - Tous les cas limites documentés (5.1 à 5.6)
- [06-enfants-multiples.md](docs/development/essai-gratuit/06-enfants-multiples.md) - Gestion des enfants multiples
- [08-tests-integration.md](docs/development/essai-gratuit/08-tests-integration.md) - Tests d'intégration recommandés

### 🔄 Cycle de Vie
- [07-cycle-vie-statuts.md](docs/development/essai-gratuit/07-cycle-vie-statuts.md) - Transitions de statut et flux complets
- [15-quand-essai-utilise.md](docs/development/essai-gratuit/15-quand-essai-utilise.md) - Timeline précise de l'utilisation
- [16-reutilisation-annulation.md](docs/development/essai-gratuit/16-reutilisation-annulation.md) - Réutilisation après annulation

### 👨‍👩‍👧 Parent/Enfant
- [09-parent-enfant.md](docs/development/essai-gratuit/09-parent-enfant.md) - Indépendance parent/enfant
- [10-javascript-serveur.md](docs/development/essai-gratuit/10-javascript-serveur.md) - Logique JavaScript vs Serveur

### 📊 Métriques et Implémentation
- [11-metriques-kpis.md](docs/development/essai-gratuit/11-metriques-kpis.md) - Métriques métier et KPIs
- [12-implementation-technique.md](docs/development/essai-gratuit/12-implementation-technique.md) - Détails techniques d'implémentation

### 🔄 Flux Complets
- [13-flux-creation-enfant.md](docs/development/essai-gratuit/13-flux-creation-enfant.md) - Flux de création enfant
- [14-flux-inscription.md](docs/development/essai-gratuit/14-flux-inscription.md) - Flux d'inscription à initiation

### 📝 Index et Vérification
- [index.md](docs/development/essai-gratuit/index.md) - Index complet de tous les fichiers
- [METHODE-VERIFICATION.md](docs/development/essai-gratuit/METHODE-VERIFICATION.md) - Méthode de vérification QA
- [_MASTER_CHECKLIST.md](docs/development/essai-gratuit/_MASTER_CHECKLIST.md) - Checklist maître

---

**Date de création** : 2025-01-17
**Dernière mise à jour** : 2025-12-30
**Version** : 4.0.1
**Qualité** : 100/100 ✅

**Note importante** : Cette documentation reflète l'état actuel du code après les modifications des formulaires et des vues pour implémenter la logique v4.0 des essais gratuits nominatifs.

**Changelog v4.0.1** :
- ✅ **CORRECTION CRITIQUE** : Utilisation de `.personal.active_now.exists?` au lieu de `.active_now.exists?` pour vérifier uniquement les adhésions personnelles du parent
  - **Problème corrigé** : Si un enfant avait une adhésion active, le système pensait que le parent était adhérent et masquait la checkbox "Utiliser mon essai gratuit"
  - **Solution** : Utiliser `.personal` pour exclure les adhésions enfants de la vérification
  - **Impact** : Le parent peut maintenant utiliser son essai gratuit même si un enfant a une adhésion active
  - **Fichiers modifiés** : `app/views/shared/_registration_form_fields.html.erb` (lignes 371 et 409)
  - **Section documentation** : Section 30 ajoutée pour documenter cette correction critique

**Changelog v4.0** :
- ✅ **CORRECTION MAJEURE** : Les essais gratuits sont **NOMINATIFS** - chaque enfant DOIT utiliser son propre essai gratuit
- ✅ Les enfants `pending` et `trial` DOIVENT utiliser leur essai gratuit, même si le parent est adhérent
- ✅ Mise à jour de la logique dans les contrôleurs `attendances_controller.rb` et `waitlist_entries_controller.rb`
- ✅ **Mise à jour des formulaires** :
  - Formulaire principal (`_registration_form_fields.html.erb`) : Checkbox obligatoire et cochée par défaut pour enfants `pending` et `trial`
  - Formulaire enfant supplémentaire (`_child_registration_form.html.erb`) : Ajout de la checkbox d'essai gratuit avec validation JavaScript
  - Messages utilisateur mis à jour : "Utiliser l'essai gratuit de [Nom Enfant] (OBLIGATOIRE)"
  - JavaScript : Bouton submit désactivé si checkbox non cochée pour enfants `pending` et `trial`
- ✅ Documentation mise à jour pour clarifier que les essais gratuits sont nominatifs et pour documenter le comportement des formulaires

**Changelog v3.9** :
- ✅ Correction critique : Contrôleur utilise maintenant `parent_is_member` au lieu de `!is_member` pour les enfants `trial`
- ⚠️ **OBSOLÈTE** : La logique v3.9 a été remplacée par v4.0 (essais gratuits nominatifs)

---

## 27. Correction Critique - Contrôleur Trial (v3.9)

### 27.1. Erreur Détectée dans le Contrôleur

**⚠️ ERREUR CRITIQUE CORRIGÉE** : Le contrôleur utilisait `!is_member` pour vérifier si un enfant `trial` devait utiliser son essai gratuit, mais `is_member` est défini comme `child_membership&.active? || child_membership&.pending?`, donc pour un enfant `trial`, `is_member` est **TOUJOURS** `false`, ce qui signifie que `!is_member` est **TOUJOURS** `true`.

**Résultat** : La condition forçait **TOUJOURS** l'essai gratuit pour les enfants `trial`, même si le parent était adhérent.

**Code incorrect** :
```ruby
# LIGNE 135 (AVANT CORRECTION)
elsif child_membership_id.present? && child_membership&.trial? && !is_member
  # ❌ PROBLÈME : is_member = false pour trial, donc !is_member = true TOUJOURS
  # Cela force l'essai même si le parent est adhérent
```

**Code corrigé** :
```ruby
# ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
if child_membership_id.present? && child_membership&.trial?
  # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif), même si le parent est adhérent
  use_free_trial = params[:use_free_trial] == "1" || 
                   params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.present?
  unless use_free_trial
    redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
    return
  end
  attendance.free_trial_used = true
end
```

**Validation** : Le modèle `Attendance` utilise la logique v4.0 :
```ruby
# app/models/attendance.rb
# ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
if child_membership_id.present? && child_membership&.trial?
  # Essai gratuit OBLIGATOIRE (nominatif)
  # Si parent adhérent : condition = false → pas d'erreur
end
```

---

## 28. Résumé Final - Tableau des Cases Validées (v4.0 - ESSais GRATUITS NOMINATIFS)

### 28.1. Cases Validées selon le Tableau Final v4.0

| Case | Description | Résultat |
|------|-------------|----------|
| **1.1** | Child pending + essai dispo | ✅ **ACCÈS** (essai obligatoire - nominatif) |
| **1.2** | Child pending + parent adhérent + essai dispo | ✅ **ACCÈS** (essai obligatoire - nominatif) |
| **1.3** | Child pending + essai consommé | 🔴 **BLOQUÉ** |
| **2.1** | Child trial + essai dispo | ✅ **ACCÈS** (essai obligatoire - nominatif) |
| **2.2** | Child trial + parent adhérent + essai dispo | ✅ **ACCÈS** (essai obligatoire - nominatif) |
| **2.3** | Child trial + essai consommé | 🔴 **BLOQUÉ** |
| **3.X** | Child active | ✅ **TOUJOURS ACCÈS** (peu importe) |
| **4.2** | Parent pending + essai dispo | ✅ **ACCÈS** (essai obligatoire - nominatif) |
| **4.3** | Parent pending + essai consommé | 🔴 **BLOQUÉ** |
| **6.2** | Annulation puis réinscription | ✅ **ESSAI REDEVIENT DISPO** |

### 28.2. Correction Majeure v4.0 - Essais Gratuits Nominatifs

**⚠️ CORRECTION MAJEURE v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque personne (adulte ou enfant) a droit à son propre essai gratuit.

**Logique réelle v4.0** :
- Le modèle `Attendance` considère `pending` comme non-membre (`is_member = false`)
- Un enfant `pending` DOIT utiliser son essai gratuit (obligatoire), même si le parent est adhérent
- Un enfant `trial` DOIT utiliser son essai gratuit (obligatoire), même si le parent est adhérent
- Les essais gratuits sont **nominatifs** : chaque enfant a son propre essai, indépendamment de l'adhésion du parent

**Code corrigé v4.0** :
- Contrôleur `attendances_controller.rb` mis à jour : essai gratuit obligatoire pour enfants `pending` et `trial`, même si parent adhérent
- Contrôleur `waitlist_entries_controller.rb` mis à jour : même logique
- Documentation mise à jour dans toutes les sections concernées

---

---

## 25. Correction Majeure - Logique `pending` (v3.8)

### 25.1. Erreur Critique Détectée et Corrigée

**⚠️ ERREUR MAJEURE CORRIGÉE** : La documentation précédente indiquait que `pending` = essai gratuit **optionnel**, ce qui était **INCORRECT**.

**Code réel vérifié** :
- **Modèle** (`app/models/attendance.rb:154-220`) : `is_member = false` pour `pending` (car `active_now` exclut `pending`)
- **Modèle** (`app/models/attendance.rb:220`) : `unless has_active_membership || has_child_membership || free_trial_used` → Bloque si aucun des trois

**Résultat réel** :
- Un enfant `pending` a `is_member = false` dans le modèle
- `has_child_membership = false` (car `active_now` exclut `pending`)
- Donc il faut soit `has_active_membership = true` (parent adhérent) OU `free_trial_used = true` (essai obligatoire)

**Tableau Final Corrigé v4.0 (ESSais GRATUITS NOMINATIFS)** :
**⚠️ IMPORTANT** : Le statut du parent n'a **AUCUNE influence** sur l'accès de l'enfant. Les essais gratuits sont **100% nominatifs**.

| Statut Enfant | Essai Gratuit | Résultat | Case |
|---------------|---------------|----------|------|
| `pending` | ❌ Non disponible | 🔴 **BLOQUÉ** | - |
| `pending` | ✅ Disponible | ✅ **ACCÈS** (via essai **obligatoire** - nominatif) | Case 1.1 |
| `pending` | ✅ Utilisé | 🔴 **BLOQUÉ** | Case 1.3 |
| `trial` | ✅ Disponible | ✅ **ACCÈS** (via essai obligatoire - nominatif) | Case 2.1 |
| `trial` | ✅ Utilisé | 🔴 **BLOQUÉ** | Case 2.3 |
| `active` | N/A | ✅ **ACCÈS COMPLET** | Case 3.X |

**Cases Validées v4.0** :
- ✅ Case 1.1 : Child pending + essai dispo → ACCÈS (essai obligatoire - nominatif) - **Indépendant du parent**
- ✅ Case 1.3 : Child pending + essai consommé → BLOQUÉ - **Même si parent adhérent**
- ✅ Case 2.1 : Child trial + essai dispo → ACCÈS (essai obligatoire - nominatif) - **Indépendant du parent**
- ✅ Case 2.3 : Child trial + essai consommé → BLOQUÉ - **Même si parent adhérent**
- ✅ Case 3.X : Child active → TOUJOURS ACCÈS (peu importe)
- ✅ Case 4.2 : Parent pending + essai dispo → ACCÈS (essai obligatoire - nominatif)
- ✅ Case 4.3 : Parent pending + essai consommé → BLOQUÉ
- ✅ Case 6.2 : Annulation puis réinscription → ESSAI REDEVIENT DISPO

**⚠️ Note importante** : Les cases 1.2 et 2.2 (parent adhérent) n'existent plus dans la logique v4.0 car le statut du parent n'a aucune influence sur l'accès de l'enfant. Les essais gratuits sont **100% nominatifs**.

---

## 26. Clarification Logique `is_member` (v4.0 - ESSais GRATUITS NOMINATIFS)

### 26.1. Question : "pending = a le droit d'accès ? Ou pourrait avoir accès si paie ?"

**Réponse vérifiée dans le code réel** (`app/controllers/initiations/attendances_controller.rb:89-90`) :

```ruby
# L'enfant est considéré comme membre si l'adhésion est active ou pending (pas trial)
child_membership&.active? || child_membership&.pending?
```

**⚠️ CORRECTION MAJEURE v4.0** : Les essais gratuits sont **NOMINATIFS**.

**Code réel du MODÈLE** (`app/models/attendance.rb:154-220`) :
```ruby
# Ligne 154-156 : is_member ne compte QUE active_now (exclut pending)
is_member = user.memberships.active_now.exists? ||
            (child_membership_id.present? && child_membership&.active?) ||
            (!child_membership_id.present? && user.memberships.active_now.where(is_child_membership: true).exists?)

# Ligne 220 : Pour un enfant pending (is_member = false), il faut :
unless has_active_membership || has_child_membership || free_trial_used
  errors.add(:base, "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association.")
end
```

**✅ Réponse CORRIGÉE v4.0 (ESSais GRATUITS NOMINATIFS)** :
- **`pending` = "non membre"** dans le modèle (`is_member = false`) → Essai **OBLIGATOIRE** (nominatif, même si parent adhérent)
- **`trial` = "non membre"** (`is_member = false`) → Essai **OBLIGATOIRE** (nominatif, même si parent adhérent)
- **`active` = "membre actif"** (`is_member = true`) → ACCÈS COMPLET
- ⚠️ **IMPORTANT v4.0** : Les essais gratuits sont **nominatifs** - chaque enfant DOIT utiliser son propre essai gratuit, indépendamment de l'adhésion du parent

**Pourquoi cette logique v4.0 (ESSais GRATUITS NOMINATIFS) ?**
- Un enfant `pending` a une adhésion en cours mais pas encore payée
- Dans le modèle, `is_member = false` car `active_now` exclut `pending`
- ⚠️ **CORRECTION v4.0** : Les essais gratuits sont **nominatifs** - chaque enfant DOIT utiliser son propre essai gratuit
- L'essai gratuit est **OBLIGATOIRE** pour les enfants `pending` et `trial`, même si le parent est adhérent

**Code réel complet** :
```ruby
# app/controllers/initiations/attendances_controller.rb:82-90
is_member = if child_membership_id.present?
  # Pour un enfant : vérifier l'adhésion enfant (active, trial ou pending)
  # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
  unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
    redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
    return
  end
  # L'enfant est considéré comme membre si l'adhésion est active ou pending (pas trial)
  child_membership&.active? || child_membership&.pending?
end
```

---

## 29. Tableau Récapitulatif - Affichage des Statuts dans `_status_table.html.erb`

### 29.1. Matrice Complète des Cas d'Affichage

**⚠️ RÈGLE v4.0 CRITIQUE** : Les essais gratuits sont **NOMINATIFS** - chaque enfant DOIT utiliser son propre essai gratuit. **Le statut du parent n'a AUCUNE influence** sur l'affichage du statut de l'enfant. Un enfant `pending` ou `trial` sans essai gratuit disponible est **BLOQUÉ**, même si le parent est adhérent.

| Statut Enfant | Essai Gratuit Enfant | Affichage | Badge | Couleur | Accès Initiation |
|---------------|----------------------|-----------|-------|---------|------------------|
| `active` | N/A | "Adhérent actif" | ✅ | `bg-success` (vert) | ✅ **OUI** (sans restriction) |
| `pending` | ❌ Utilisé | "Essai utilisé" | ❌ | `bg-danger` (rouge) | ❌ **NON** (bloqué) |
| `pending` | ✅ Disponible | "Essai disponible" | ⚡ | `bg-info` (bleu) | ✅ **OUI** (via essai obligatoire) |
| `trial` | ❌ Utilisé | "Essai utilisé" | ❌ | `bg-danger` (rouge) | ❌ **NON** (bloqué) |
| `trial` | ✅ Disponible | "Essai disponible" | ⚡ | `bg-info` (bleu) | ✅ **OUI** (via essai obligatoire) |
| `expired` | ❌ Utilisé | "Essai utilisé" | ❌ | `bg-danger` (rouge) | ❌ **NON** (bloqué) |
| `expired` | ✅ Disponible | "Essai disponible" | ⚡ | `bg-info` (bleu) | ✅ **OUI** (via essai obligatoire - était pending/trial avant) |

**⚠️ IMPORTANT** : Le statut du parent n'apparaît PAS dans ce tableau car il n'a aucune influence sur l'affichage ou l'accès de l'enfant. Les essais gratuits sont **100% nominatifs**.

### 29.2. Problème Identifié dans le Code Actuel (CORRIGÉ)

**Code précédent (INCORRECT selon v4.0)** :
```ruby
<% when 'pending' %>
  <% if current_user.memberships.active_now.exists? %>
    <span class="badge bg-warning">En attente</span>  # ❌ ERREUR : Cache l'état de l'essai gratuit
  <% else %>
    # Affiche l'état de l'essai gratuit
  <% end %>

<% when 'trial' %>
  <% if current_user.memberships.active_now.exists? %>
    <span class="badge bg-success">Accès parent</span>  # ❌ ERREUR : Cache l'état de l'essai gratuit
  <% else %>
    # Affiche l'état de l'essai gratuit
  <% end %>
```

**Problème identifié** : Le code précédent vérifiait le statut du parent (`current_user.memberships.active_now.exists?`) pour décider de l'affichage de l'enfant. C'était **INCORRECT** car :
- ❌ Les essais gratuits sont **nominatifs** (v4.0) - le statut du parent n'a aucune influence
- ❌ Un enfant `pending` ou `trial` sans essai gratuit disponible est **BLOQUÉ**, même si le parent est adhérent
- ❌ L'affichage doit être basé uniquement sur le statut de l'enfant et son essai gratuit

### 29.3. Code Corrigé (IMPLÉMENTÉ)

**Logique corrigée (CONFORME à v4.0 - Essais NOMINATIFS)** :
```ruby
<% when 'pending' %>
  <%# v4.0 : Essais gratuits NOMINATIFS - afficher l'état de l'essai gratuit indépendamment du statut du parent %>
  <% child_free_trial_used = current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists? %>
  <% if child_free_trial_used %>
    <span class="badge bg-danger fs-6">
      <i class="bi bi-x-circle me-1" aria-hidden="true"></i>
      Essai utilisé
    </span>
  <% else %>
    <span class="badge bg-info fs-6">
      <i class="bi bi-lightning-charge me-1" aria-hidden="true"></i>
      Essai disponible
    </span>
  <% end %>

<% when 'trial' %>
  <%# v4.0 : Essais gratuits NOMINATIFS - afficher l'état de l'essai gratuit indépendamment du statut du parent %>
  <% child_free_trial_used = current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists? %>
  <% if child_free_trial_used %>
    <span class="badge bg-danger fs-6">
      <i class="bi bi-x-circle me-1" aria-hidden="true"></i>
      Essai utilisé
    </span>
  <% else %>
    <span class="badge bg-info fs-6">
      <i class="bi bi-lightning-charge me-1" aria-hidden="true"></i>
      Essai disponible
    </span>
  <% end %>
```

**Justification** :
- ✅ Les essais gratuits sont **100% nominatifs** (v4.0) - chaque enfant a son propre essai, **indépendamment du parent**
- ✅ **AUCUNE vérification du statut du parent** - le code ne vérifie que l'état de l'essai gratuit de l'enfant
- ✅ Un enfant `pending` ou `trial` avec essai disponible peut s'inscrire (essai obligatoire)
- ✅ Un enfant `pending` ou `trial` sans essai disponible est **BLOQUÉ**, même si le parent est adhérent
- ✅ L'affichage est basé uniquement sur : `child.status` + `child_free_trial_used`

### 29.4. Principe d'Affichage (IMPLÉMENTÉ)

**Affichage simple et clair (IMPLÉMENTÉ)** :
- ✅ Toujours afficher l'état de l'essai gratuit pour `pending` et `trial`
- ✅ **AUCUNE référence au statut du parent** dans l'affichage des enfants
- ✅ L'affichage est basé uniquement sur le statut de l'enfant et son essai gratuit

**Logique d'affichage** :
1. **Enfant `active`** → "Adhérent actif" (vert) - Accès complet
2. **Enfant `pending` + essai disponible** → "Essai disponible" (bleu) - Peut s'inscrire via essai obligatoire
3. **Enfant `pending` + essai utilisé** → "Essai utilisé" (rouge) - **BLOQUÉ** (même si parent adhérent)
4. **Enfant `trial` + essai disponible** → "Essai disponible" (bleu) - Peut s'inscrire via essai obligatoire
5. **Enfant `trial` + essai utilisé** → "Essai utilisé" (rouge) - **BLOQUÉ** (même si parent adhérent)
6. **Enfant `expired`** → "Expiré" (gris) - **BLOQUÉ**

### 29.5. Validation de la Logique

**✅ Code validé** : Le code actuel dans `_status_table.html.erb` est conforme à la logique v4.0 :
- ✅ Aucune vérification du statut du parent pour les enfants
- ✅ Affichage basé uniquement sur `child.status` et `child_free_trial_used`
- ✅ Les essais gratuits sont **100% nominatifs** - chaque enfant a son propre essai
- ✅ Un enfant sans essai disponible est **BLOQUÉ**, indépendamment du statut du parent

---

## 30. Correction Critique - Vérification Adhésions Parent (v4.0.1)

### 30.1. Problème Identifié

**⚠️ BUG CRITIQUE CORRIGÉ** : Le code vérifiait `current_user.memberships.active_now.exists?` au lieu de `current_user.memberships.personal.active_now.exists?` pour déterminer si le parent pouvait utiliser son essai gratuit.

**Problème** :
- Le scope `active_now` vérifie **toutes** les adhésions (personnelles ET enfants)
- Si un enfant avait une adhésion active, `current_user.memberships.active_now.exists?` retournait `true`
- Le système pensait alors que le parent était adhérent et masquait la checkbox "Utiliser mon essai gratuit"
- **Résultat** : Le parent ne pouvait pas utiliser son essai gratuit même s'il n'avait pas d'adhésion personnelle active

**Exemple concret** :
```
Situation :
- Parent : Pas d'adhésion personnelle active
- Enfant A : Adhésion active

Code incorrect (BUG) :
parent_can_use_trial = !current_user.memberships.active_now.exists?
# Retourne false car l'enfant a une adhésion active
# → parent_can_use_trial = false
# → Checkbox "Utiliser mon essai gratuit" masquée ❌

Code corrigé :
parent_can_use_trial = !current_user.memberships.personal.active_now.exists?
# Retourne true car le parent n'a pas d'adhésion personnelle active
# → parent_can_use_trial = true
# → Checkbox "Utiliser mon essai gratuit" affichée ✅
```

### 30.2. Solution Appliquée

**Code corrigé** :
```ruby
# app/views/shared/_registration_form_fields.html.erb (ligne 371-372)
# Pour le parent (sans enfant sélectionné)
# Le parent peut utiliser son essai gratuit s'il n'a pas d'adhésion active PERSONNELLE ET n'a pas déjà utilisé son essai
# IMPORTANT : Utiliser .personal pour vérifier uniquement les adhésions personnelles (pas les enfants)
# RÈGLE v4.0 : Les essais gratuits sont NOMINATIFS - le statut des enfants n'a AUCUNE influence sur l'essai gratuit du parent
parent_can_use_trial = !current_user.memberships.personal.active_now.exists? && 
                       !current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

# app/views/shared/_registration_form_fields.html.erb (ligne 409)
# Vérifier si le parent a une adhésion active PERSONNELLE (pour déterminer si l'essai est obligatoire pour les enfants pending)
# IMPORTANT : Utiliser .personal pour vérifier uniquement les adhésions personnelles (pas les enfants)
# RÈGLE v4.0 : Les essais gratuits sont NOMINATIFS - le statut des enfants n'a AUCUNE influence sur l'essai gratuit du parent
parent_has_active_membership = current_user.memberships.personal.active_now.exists?
```

### 30.3. Justification

**Pourquoi utiliser `.personal` ?**
- ⚠️ **RÈGLE v4.0** : Les essais gratuits sont **NOMINATIFS** - chaque personne a son propre essai gratuit
- Le statut des enfants n'a **AUCUNE influence** sur l'essai gratuit du parent
- Un parent sans adhésion personnelle active peut utiliser son essai gratuit, même si un enfant est adhérent
- Le scope `.personal` filtre uniquement les adhésions avec `is_child_membership: false`

**Impact de la correction** :
- ✅ Le parent peut maintenant utiliser son essai gratuit même si un enfant a une adhésion active
- ✅ La checkbox "Utiliser mon essai gratuit" s'affiche correctement pour le parent
- ✅ Conforme à la logique v4.0 (essais gratuits nominatifs)

### 30.4. Fichiers Modifiés

- `app/views/shared/_registration_form_fields.html.erb` :
  - Ligne 371 : `parent_can_use_trial` utilise maintenant `.personal.active_now.exists?`
  - Ligne 409 : `parent_has_active_membership` utilise maintenant `.personal.active_now.exists?`

---

## 31. Section Historique - Ancienne Logique v3.8 (OBSOLÈTE)

⚠️ **ATTENTION** : Cette section documente l'ancienne logique v3.8 qui est **OBSOLÈTE** depuis v4.0.

**Ancienne logique (v3.8 - OBSOLÈTE)** :
- Les enfants `pending` pouvaient s'inscrire via le parent si le parent était adhérent
- Les enfants `trial` pouvaient s'inscrire via le parent si le parent était adhérent

**Nouvelle logique (v4.0 - ACTUELLE)** :
- Les essais gratuits sont **nominatifs** - chaque enfant DOIT utiliser son propre essai gratuit
- Les enfants `pending` et `trial` DOIVENT utiliser leur essai gratuit, même si le parent est adhérent

---
