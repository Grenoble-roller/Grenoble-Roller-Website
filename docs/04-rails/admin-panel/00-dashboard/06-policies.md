# 🔐 POLICIES - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13

---

## 📋 Description

Policies Pundit pour le dashboard et la maintenance.

---

## ✅ Policy 1 : DashboardPolicy (EXISTANT - Vérifier)

**Fichier** : `app/policies/admin_panel/dashboard_policy.rb`

**Status** : ✅ **EXISTE** (hérite de BasePolicy)

**Note** : Le Dashboard utilise `BasePolicy` qui vérifie déjà que l'utilisateur est admin (level >= 60).

---

## ✅ Policy 2 : MaintenancePolicy ✅ CRÉÉE

**Fichier** : `app/policies/admin_panel/maintenance_policy.rb`

**Status** : ✅ **CRÉÉE ET FONCTIONNELLE** (2025-01-13)

**Code implémenté** :
```ruby
# frozen_string_literal: true

module AdminPanel
  # Policy pour le mode maintenance
  # MaintenanceMode n'est pas un modèle ActiveRecord, donc on utilise une classe wrapper
  class MaintenancePolicy < BasePolicy
    # Seuls les admins/superadmins peuvent activer/désactiver le mode maintenance
    def toggle?
      admin_user? # level >= 60 (ADMIN ou SUPERADMIN)
    end
  end
end
```

### **Sécurité** :
- ✅ Vérifie que l'utilisateur est admin (level >= 60)
- ✅ Double vérification : BaseController + Policy
- ✅ Utilisée dans `MaintenanceController#toggle`

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)** ✅ COMPLÉTÉ
- [x] Vérifier DashboardPolicy ✅ (utilise BasePolicy)
- [x] Créer MaintenancePolicy ✅
- [x] Tester autorisations ✅

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
