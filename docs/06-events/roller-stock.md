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

**Trois options** (retour automatique désactivé tant que non validé par le staff) :

1. **Bouton "Tout remettre en stock"** (recommandé pour un rattrapage global) : **Admin Panel → Stock Rollers** (Gestion de stock). Un clic remet en stock tous les rollers des initiations **déjà terminées** et non encore marquées « Matériel rendu », et marque chaque initiation concernée comme si vous aviez cliqué « Matériel rendu » sur sa page Présences. Idéal pour rattraper plusieurs initiations d’un coup.
2. **Bouton "Matériel rendu" par initiation** : Admin Panel → Initiations → [Initiation] → Présences. Le bouton apparaît si l’initiation est passée, qu’il y a du matériel prêté et qu’il n’a pas encore été rendu.
3. **Job automatique** : `ReturnRollerStockJob` existe mais est **désactivé** (schedule.rb + recurring.yml) en attente de validation par le staff. Une fois validé, il pourra être réactivé (tous les jours à 2h).

**Permissions** : Grade INITIATION (level 40) ou plus pour « Matériel rendu » ; accès Admin Panel (RollerStock) pour « Tout remettre en stock ».

**Impact du bouton "Tout remettre en stock"** :
- Cible : toutes les initiations **terminées** (`start_at + duration_min <= now`) avec `stock_returned_at` nil et au moins une attendance avec matériel (non annulée).
- Action : pour chaque telle initiation, appelle `Event#return_roller_stock` (incrémente `RollerStock` par taille, puis met à jour `stock_returned_at`). Aucun double traitement grâce à `stock_returned_at`.
- Résultat : les quantités par taille dans Gestion de stock augmentent ; les initiations concernées affichent « Matériel rendu le [date] » sur la page Présences.
- Aucun impact sur les initiations à venir ni sur les inscriptions en attente.

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
- **Retour matériel** : bouton **"Tout remettre en stock"** dans Gestion de stock (Admin Panel → Stock Rollers) + bouton **"Matériel rendu"** par initiation (page Présences). Job automatique (`ReturnRollerStockJob`) désactivé en attente validation staff.

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

### Bouton "Tout remettre en stock" dans Gestion de stock

**Fichier** : `app/views/admin_panel/roller_stocks/index.html.erb`  
**Action** : `POST /admin-panel/roller-stocks/return_all`  
**Controller** : `AdminPanel::RollerStocksController#return_all`

- Remet en stock tous les rollers des initiations **déjà terminées** et non encore marquées « Matériel rendu ».
- Équivalent à cliquer « Matériel rendu » sur chaque initiation concernée.
- Confirmation Turbo avant envoi. Permission : accès Admin Panel (RollerStock).

### Bouton "Matériel rendu" dans Présences

**Fichier** : `app/views/admin_panel/initiations/presences.html.erb`

- Affiché uniquement pour les initiations passées avec matériel prêté
- Masqué si le matériel a déjà été rendu (badge avec date affiché à la place)
- Action : `POST /admin-panel/initiations/:id/return_material`
- Permission : Grade INITIATION (level 40) ou plus

## ⚠️ Limitations Actuelles

### Stock global (une seule réserve par taille)

- Le stock est **global** : une taille (ex. 38) a une quantité unique partagée entre toutes les initiations.
- **Comportement attendu** : une paire réservée pour une initiation du 01/01 est **libérée après** cette initiation (bouton "Tout remettre en stock" ou "Matériel rendu" par initiation ; job automatique désactivé en attente validation staff), donc à nouveau disponible pour une initiation du 05/01.
- Les événements **simultanés** (même jour / même créneau) partagent le même stock ; l’organisateur doit vérifier la disponibilité.

**Alternative non implémentée** : stock "par initiation" (chaque initiation aurait son propre pool de tailles) — évolution plus lourde.

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

1. **Stock par initiation** : Chaque initiation avec son propre pool de tailles (évolution lourde)
2. **Alertes stock faible** : Notification admin quand quantité < seuil
3. **Historique prêts** : Suivi des prêts par participant/événement
4. **États des rollers** : Suivi de l'état (neuf, usé, réparation)

---

## 📝 Changelog

### Version 2.2 (2026-01-31)
- ✅ **Bouton "Tout remettre en stock"** dans Gestion de stock (Admin Panel → Stock Rollers) : remet en stock tous les rollers des initiations déjà terminées et non encore marquées « Matériel rendu », et marque chaque initiation comme si « Matériel rendu » avait été cliqué. Idéal pour rattrapage global.
- ⏸️ **Retour automatique désactivé** : `ReturnRollerStockJob` reste désactivé (schedule.rb + recurring.yml) en attente de validation par le staff. Utiliser le bouton "Tout remettre en stock" ou "Matériel rendu" par initiation en attendant.
- ✅ Documentation : impact et usage du bouton "Tout remettre en stock" décrits avec les autres options de retour.

### Version 2.1 (2026-01-31)
- ✅ **Correction job** : `ReturnRollerStockJob` traite toutes les initiations **déjà terminées** (plus de fenêtre 24h sur le début). Job désactivé en 2.2 en attente validation staff.

### Version 2.0 (2025-01-13)
- ✅ Ajout du bouton "Matériel rendu" dans la page Présences
- ✅ Gestion automatique du stock (décrémentation/incrémentation)
- ✅ Méthode `has_equipment_loaned?` pour vérifier le matériel prêté
- ✅ Permissions : Grade INITIATION (level 40) peut faire le retour matériel

### Version 1.0 (2025-01-30)
- Documentation initiale

---

**Version** : 2.2  
**Dernière mise à jour** : 2026-01-31

