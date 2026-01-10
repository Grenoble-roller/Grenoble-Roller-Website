# 🗄️ MIGRATIONS - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Migrations nécessaires pour les initiations.

**Note** : Les tables principales existent déjà (`events`, `attendances`, `waitlist_entries`, `roller_stocks`). Aucune migration supplémentaire n'est nécessaire pour le MVP.

---

## ✅ Migrations Existantes

Les tables suivantes existent déjà et sont utilisées :

- `events` - Table principale (STI pour `Event::Initiation`)
- `attendances` - Participations aux initiations
- `waitlist_entries` - Liste d'attente
- `roller_stocks` - Stock de rollers

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Vérifier migrations nécessaires → Aucune migration nécessaire
- [x] Tables existantes confirmées

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
