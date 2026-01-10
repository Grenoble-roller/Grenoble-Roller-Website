---
title: "Gestion du Stock de Rollers (RollerStock) - Grenoble Roller"
status: "active"
version: "2.0"
created: "2025-01-30"
updated: "2025-01-13"
tags: ["roller-stock", "equipment", "inventory", "initiations"]
---

# Gestion du Stock de Rollers (RollerStock)

**Dernière mise à jour** : 2025-01-13

Ce document décrit le système de gestion de l'inventaire des rollers en prêt pour les initiations et événements.

---

## 📋 Vue d'Ensemble

Le modèle `RollerStock` permet de gérer l'inventaire des rollers disponibles en prêt pour les participants aux initiations et événements. Chaque taille de roller a une quantité disponible qui peut être suivie et mise à jour.

### Cas d'Usage

- **Initiations** : Prêt de rollers aux participants qui n'ont pas leur propre équipement
- **Événements** : Prêt ponctuel de rollers si nécessaire
- **Gestion admin** : Suivi des stocks, activation/désactivation de tailles

---

## 🏗️ Modèle : `RollerStock`

**Fichier** : `app/models/roller_stock.rb`

### Attributs

| Attribut | Type | Description |
|----------|------|-------------|
| `size` | string | Taille du roller (en EU : 28 à 48) |
| `quantity` | integer | Quantité disponible (>= 0) |
| `is_active` | boolean | Taille activée/désactivée |

### Constantes

```ruby
SIZES = %w[28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48].freeze
```

**Tailles supportées** : 28 à 48 (système de pointure européenne)

### Validations

- `size` : présence, unicité, inclusion dans `SIZES`
- `quantity` : présence, >= 0, entier
- `is_active` : inclusion dans `[true, false]`

### Scopes

- `active` : Tailles actives (`is_active = true`)
- `available` : Tailles actives avec stock > 0
- `ordered_by_size` : Tri par taille numérique (ordre croissant)

### Méthodes

#### Instance

- `available?` : Retourne `true` si actif et quantité > 0
- `out_of_stock?` : Retourne `true` si quantité <= 0
- `size_with_stock` : Format "XX (Y disponible(s))" pour affichage

#### Classe

- `ransackable_attributes` : Attributs recherchables (ActiveAdmin)
- `ransackable_associations` : Associations recherchables (aucune)

### Hashid

Le modèle utilise `include Hashid::Rails` pour générer des identifiants URL-friendly.

---

## 🔗 Intégration avec Attendance et WaitlistEntry

### Validation des Tailles

Les modèles `Attendance` et `WaitlistEntry` utilisent `RollerStock::SIZES` pour valider les tailles :

```ruby
# Dans Attendance
validates :roller_size, presence: true, if: :needs_equipment?
validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?

# Dans WaitlistEntry
validates :roller_size, presence: true, if: :needs_equipment?
validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?
```

### Champ `needs_equipment`

Dans les formulaires d'inscription :

- Si `needs_equipment = true` → `roller_size` est obligatoire
- `roller_size` doit être dans `RollerStock::SIZES`
- Utilisé pour :
  - **Attendance** : Inscriptions aux événements/initiations
  - **WaitlistEntry** : Inscriptions en liste d'attente

### Affichage dans les Formulaires

**Exemple** : Dropdown de sélection de taille

```erb
<%= f.select :roller_size, 
    options_for_select(
      RollerStock.available.ordered_by_size.map { |rs| 
        [rs.size_with_stock, rs.size] 
      },
      selected: f.object.roller_size
    ),
    { include_blank: "Sélectionner une taille" },
    { required: true, class: "form-select" }
%>
```

**Format** : "35 (3 disponibles)" ou "36 (1 disponible)"

---

## 🎯 Cas d'Usage

### 1. Inscription avec Prêt de Rollers

**Scénario** : Participant sans rollers veut s'inscrire à une initiation

1. Coche `needs_equipment = true`
2. Sélectionne `roller_size` dans le dropdown
3. Le système valide que la taille est dans `RollerStock::SIZES`
4. L'inscription est créée avec ces informations
5. L'organisateur peut ensuite voir les demandes de matériel

### 2. Gestion Admin du Stock

**ActiveAdmin** : Interface admin pour gérer le stock

- Lister toutes les tailles
- Modifier les quantités
- Activer/désactiver des tailles
- Rechercher/filtrer par taille, quantité, statut

**Actions** :
- `quantity += 1` : Ajout de rollers (achat, retour)
- `quantity -= 1` : Retrait de rollers (prêt, perte)
- `is_active = false` : Désactiver une taille (plus disponible)

### 3. Affichage Stock Disponible

**Dans les formulaires** :
- Seules les tailles actives avec stock > 0 sont affichées
- Format : "XX (Y disponible(s))"
- Tri par taille numérique

**Dans les exports admin** :
- Liste des demandes d'équipement avec tailles
- Export CSV des participants avec matériel demandé

---

## 📊 Exports et Rapports

### Export Demandes d'Équipement

**Fichier** : `app/admin/attendances.rb` (ActiveAdmin)

```ruby
# Export CSV des participants avec demande de matériel
csv << [att.user.full_name, att.user.email, att.user.phone, att.roller_size]
```

**Utilisation** : Permet aux organisateurs de préparer les rollers à prêter

### Notes d'Équipement

Le champ `equipment_note` (text) dans `Attendance` permet d'ajouter des notes supplémentaires sur la demande d'équipement.

---

## 🔄 Workflow Gestion Stock

### Ajout de Rollers

1. Admin va dans ActiveAdmin → RollerStock
2. Sélectionne la taille ou crée une nouvelle entrée
3. Augmente `quantity`
4. Active `is_active` si nécessaire

### Prêt de Rollers

1. Participant s'inscrit avec `needs_equipment = true` et `roller_size`
2. **Le stock est automatiquement décrémenté** lors de la création de l'inscription (`Attendance#after_create`)
3. Organisateur exporte la liste des demandes
4. Rollers préparés et prêtés le jour de l'initiation

**Gestion automatique du stock** :
- Lors de l'inscription : `quantity` est décrémenté automatiquement
- Si annulation : `quantity` est incrémenté automatiquement
- Si changement de taille : l'ancienne taille est incrémentée, la nouvelle décrémentée

### Retour de Rollers

**Méthode manuelle via le bouton "Matériel rendu"** (recommandée) :

1. Après l'initiation, aller dans **Admin Panel → Initiations → [Initiation] → Présences**
2. Le bouton **"Matériel rendu"** apparaît automatiquement si :
   - L'initiation est passée (`start_at <= Time.current`)
   - Il y a du matériel prêté (`has_equipment_loaned?`)
   - Le matériel n'a pas encore été rendu (`stock_returned_at.nil?`)
3. Cliquer sur le bouton → Confirmation → Les rollers sont remis en stock automatiquement
4. Le bouton disparaît et un badge indique la date de retour

**Permissions** : Grade INITIATION (level 40) ou plus

**Méthode technique** :
- La méthode `Event#return_roller_stock` incrémente le stock pour chaque taille prêtée
- La colonne `stock_returned_at` dans `events` empêche les retraitements multiples
- Seules les attendances non annulées sont traitées

---

## ✅ Fonctionnalités Implémentées

### Gestion Automatique du Stock

- **Décrémentation automatique** lors de l'inscription avec matériel
- **Incrémentation automatique** lors de l'annulation
- **Gestion des changements** de taille (swap automatique)
- **Retour matériel** via bouton manuel dans la page Présences

### Méthode `Event#return_roller_stock`

**Fichier** : `app/models/event.rb`

```ruby
def return_roller_stock
  return unless is_a?(Event::Initiation)
  
  # Sécurité : éviter de remettre le stock plusieurs fois
  return nil if stock_returned_at.present?
  
  # Traiter toutes les attendances avec matériel (non annulées)
  # Incrémenter le stock pour chaque taille
  # Marquer stock_returned_at pour éviter les retraitements
end
```

**Méthode `Event#has_equipment_loaned?`** : Vérifie s'il y a du matériel prêté pour l'événement

### Bouton "Matériel rendu" dans Présences

**Fichier** : `app/views/admin_panel/initiations/presences.html.erb`

- Affiché uniquement pour les initiations passées avec matériel prêté
- Masqué si le matériel a déjà été rendu (badge avec date affiché à la place)
- Action : `POST /admin-panel/initiations/:id/return_material`
- Permission : Grade INITIATION (level 40) ou plus

## ⚠️ Limitations Actuelles

### Stock Global (pas par événement)

- Le stock est global (pas de réservation spécifique par événement)
- Les événements simultanés partagent le même stock
- L'organisateur doit vérifier manuellement la disponibilité pour les événements simultanés

**Note** : Le système gère correctement les annulations et changements, mais ne réserve pas le stock à l'avance pour un événement spécifique.

---

## 📝 Notes Techniques

### Tri Numérique

Le tri par taille utilise `CAST(size AS INTEGER)` pour trier numériquement :

```ruby
scope :ordered_by_size, -> { order(Arel.sql("CAST(size AS INTEGER)")) }
```

**Raison** : Sans cast, "28" < "3" (tri alphabétique), ce qui est incorrect.

### ActiveAdmin Integration

Le modèle expose `ransackable_attributes` et `ransackable_associations` pour permettre la recherche et le filtrage dans ActiveAdmin.

### Hashid

Utilisation de `Hashid::Rails` pour générer des identifiants URL-friendly (utile pour les liens admin ou API).

---

## 🔗 Références

- **Modèle** : `app/models/roller_stock.rb`
- **Intégration Attendance** : `app/models/attendance.rb` (champ `roller_size`, validation)
- **Intégration WaitlistEntry** : `app/models/waitlist_entry.rb` (champ `roller_size`, validation)
- **Admin** : ActiveAdmin configuration (à vérifier dans `app/admin/`)

---

## 🎯 Améliorations Futures Possibles

1. **Gestion par événement** : Stock réservé par événement avec libération après (évite les conflits entre événements simultanés)
2. **Alertes stock faible** : Notification admin quand quantité < seuil
3. **Historique prêts** : Suivi des prêts par participant/événement
4. **États des rollers** : Suivi de l'état (neuf, usé, réparation)
5. **Job automatique optionnel** : Possibilité de réactiver le job automatique pour les retours (actuellement désactivé)

---

## 📝 Changelog

### Version 2.0 (2025-01-13)
- ✅ Ajout du bouton "Matériel rendu" dans la page Présences
- ✅ Gestion automatique du stock (décrémentation/incrémentation)
- ✅ Méthode `has_equipment_loaned?` pour vérifier le matériel prêté
- ✅ Job automatique désactivé (remplacé par bouton manuel)
- ✅ Permissions : Grade INITIATION (level 40) peut faire le retour matériel

### Version 1.0 (2025-01-30)
- Documentation initiale

---

**Version** : 2.0  
**Dernière mise à jour** : 2025-01-13

