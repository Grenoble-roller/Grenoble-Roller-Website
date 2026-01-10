# 📢 COMMUNICATION - Plan d'Implémentation

**Priorité** : 🟢 BASSE | **Phase** : 7 | **Semaine** : 7+

---

## 📋 Vue d'ensemble

Gestion des messages de contact et partenaires.

**Status actuel** : ✅ Existe dans ActiveAdmin - À migrer vers AdminPanel

**Note importante** : Il n'existe **pas de formulaire de contact** actuellement. Il faut **créer un formulaire** pour permettre aux utilisateurs de contacter l'association.

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
- [`01-migrations.md`](./01-migrations.md) - Migrations (code exact)
- [`02-modeles.md`](./02-modeles.md) - Modèles (code exact)
- [`03-services.md`](./03-services.md) - Services (code exact)
- [`04-controllers.md`](./04-controllers.md) - Controllers (code exact)
- [`05-routes.md`](./05-routes.md) - Routes (code exact)
- [`06-policies.md`](./06-policies.md) - Policies (code exact)
- [`07-vues.md`](./07-vues.md) - Vues ERB (code exact)
- [`08-javascript.md`](./08-javascript.md) - JavaScript (code exact)

### **📁 Fichiers par fonctionnalité**
- [`messages-contact.md`](./messages-contact.md) - Messages de contact
- [`partenaires.md`](./partenaires.md) - Gestion partenaires

---

## 🎯 Fonctionnalités Incluses

### ✅ ContactMessages (Messages de Contact)
- **⚠️ À CRÉER** : Formulaire de contact public (pas de formulaire actuellement)
- Liste avec filtres (nom, email, sujet, date)
- Lecture seule dans AdminPanel (pas de création/édition)
- Action "Répondre" (mailto)
- Suppression

### ✅ Partners (Partenaires)
- Liste avec scopes (actifs, inactifs)
- CRUD complet
- Gestion logo (URL ou upload)
- Activation/désactivation

---

## ✅ Checklist Globale

### **Phase 7 (Semaine 7+)**
- [x] **CRÉER** : Formulaire de contact public ✅ **IMPLÉMENTÉ** (controller + vue publique)
- [x] Controller ContactMessages (AdminPanel) ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Controller Partners ✅ **IMPLÉMENTÉ** (CRUD complet)
- [x] Policies (ContactMessages, Partners) ✅ **IMPLÉMENTÉES** (level >= 60)
- [x] Routes (publique + admin) ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues (formulaire public + admin index/show) ✅ **IMPLÉMENTÉES**
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Communication)
- [x] Tests RSpec ✅ **36 exemples, 0 échecs**

---

## 📊 Estimation

- **Temps** : 1 semaine
- **Complexité** : ⭐⭐
- **Dépendances** : Aucune

---

**Retour** : [INDEX principal](../INDEX.md)
