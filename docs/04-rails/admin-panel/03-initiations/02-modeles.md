# 🏗️ MODÈLES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Modèles utilisés pour les initiations. Tous les modèles existent déjà, vérification des méthodes nécessaires.

---

## ✅ Modèles Utilisés

### **1. Event::Initiation**

**Fichier** : `app/models/event/initiation.rb`

**Méthodes clés disponibles** :
- `full?` - Vérifie si l'initiation est complète
- `available_places` - Nombre de places disponibles
- `participants_count` - Nombre de participants (hors bénévoles)
- `volunteers_count` - Nombre de bénévoles
- `upcoming_initiations` - Scope pour initiations à venir
- `by_season(season)` - Scope par saison (⚠️ **Non utilisé** - Filtre saison retiré de l'interface)

**Associations** :
- `has_many :attendances`
- `has_many :waitlist_entries`
- `belongs_to :creator_user`

---

### **2. Attendance**

**Fichier** : `app/models/attendance.rb`

**Méthodes clés disponibles** :
- `participant_name` - Nom du participant (parent ou enfant)
- `for_child?` - Vérifie si c'est pour un enfant
- `for_parent?` - Vérifie si c'est pour le parent
- `needs_equipment?` - Vérifie si matériel demandé

**Champs importants** :
- `is_volunteer` - Boolean (bénévole ou participant)
- `free_trial_used` - Boolean (essai gratuit utilisé)
- `equipment_note` - Text (demande matériel)
- `roller_size` - String (taille roller)
- `status` - Enum (registered, present, absent, canceled, no_show)

**Scopes** :
- `volunteers` - Bénévoles uniquement
- `participants` - Participants uniquement
- `active` - Exclut canceled

---

### **3. WaitlistEntry**

**Fichier** : `app/models/waitlist_entry.rb`

**Méthodes clés disponibles** :
- `participant_name` - Nom du participant
- `notify!` - Notifie la personne
- `convert!` - Convertit en inscription
- `refuse!` - Refuse la place

**Champs importants** :
- `status` - Enum (pending, notified, converted, cancelled)
- `position` - Integer (position dans la queue)

**Scopes** :
- `active` - pending ou notified
- `for_event(event)` - Pour un événement
- `ordered_by_position` - Tri par position

---

### **4. RollerStock**

**Fichier** : `app/models/roller_stock.rb`

**Méthodes clés disponibles** :
- `available?` - Vérifie si disponible (actif et stock > 0)
- `out_of_stock?` - Vérifie si rupture de stock
- `size_with_stock` - Format "28 (5 disponibles)"

**Champs importants** :
- `size` - String (tailles EU : 28-48)
- `quantity` - Integer (quantité disponible)
- `is_active` - Boolean (actif ou non)

**Scopes** :
- `active` - Actifs uniquement
- `available` - Actifs avec stock > 0
- `ordered_by_size` - Tri par taille

**Constante** :
- `SIZES` - Array des tailles valides (28-48)

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Vérifier Event::Initiation → OK, méthodes disponibles
- [x] Vérifier Attendance → OK, méthodes disponibles
- [x] Vérifier WaitlistEntry → OK, méthodes disponibles
- [x] Vérifier RollerStock → OK, méthodes disponibles

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
