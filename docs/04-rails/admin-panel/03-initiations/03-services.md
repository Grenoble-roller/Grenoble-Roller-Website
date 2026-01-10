# 🔧 SERVICES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Services pour gérer les initiations. Aucun service spécifique nécessaire pour le MVP, la logique métier est dans les modèles.

---

## ✅ Services Existants

### **WaitlistEntry (méthodes de classe)**

**Fichier** : `app/models/waitlist_entry.rb`

**Méthodes disponibles** :
- `WaitlistEntry.add_to_waitlist(user, event, ...)` - Ajouter à la liste d'attente
- `WaitlistEntry.notify_next_in_queue(event, count: 1)` - Notifier la prochaine personne
- `WaitlistEntry.reorganize_positions(event)` - Réorganiser les positions

Ces méthodes sont déjà implémentées dans le modèle et peuvent être utilisées directement.

---

## ✅ Services Optionnels (Phase 2)

Pour la Phase 2, on pourra créer :

- `InitiationExporter` - Export CSV des participants
- `PresenceService` - Gestion bulk des présences
- `InitiationStatsService` - Calcul de statistiques

**Pour l'instant** : Pas nécessaire pour le MVP.

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Vérifier services nécessaires → Aucun service nécessaire pour MVP
- [ ] Services Phase 2 (optionnel)

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
