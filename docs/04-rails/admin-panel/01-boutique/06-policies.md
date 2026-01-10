# 🔐 POLICIES - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 2 | **Semaine** : 2

---

## 📋 Description

Policies Pundit pour autoriser l'accès aux ressources Boutique.

---

## ✅ Policy 1 : ProductPolicy (EXISTANT - Vérifier)

**Fichier** : `app/policies/admin_panel/product_policy.rb`

**Code existant** :
```ruby
module AdminPanel
  class ProductPolicy < BasePolicy
    # Seuls les admins peuvent gérer les produits
    # Les méthodes héritent de BasePolicy qui vérifie admin_user?
  end
end
```

**Vérification** : BasePolicy doit avoir `admin_user?` qui vérifie le rôle.

**Checklist** :
- [x] Vérifier BasePolicy a `admin_user?`
- [x] Tester autorisations produits

---

## ✅ Policy 2 : ProductVariantPolicy (À CRÉER)

**Fichier** : `app/policies/admin_panel/product_variant_policy.rb`

**Code exact** :
```ruby
module AdminPanel
  class ProductVariantPolicy < BasePolicy
    # Hérite de BasePolicy qui vérifie admin_user?
    # Pas besoin de redéfinir les méthodes si logique identique
  end
end
```

**Checklist** :
- [x] Créer fichier `app/policies/admin_panel/product_variant_policy.rb`
- [x] Vérifier autorisations dans ProductVariantsController

---

## ✅ Policy 3 : InventoryPolicy (NOUVEAU)

**Fichier** : `app/policies/admin_panel/inventory_policy.rb`

**Code exact** :
```ruby
module AdminPanel
  class InventoryPolicy < BasePolicy
    def index?
      admin_user?
    end
    
    def transfers?
      admin_user?
    end
    
    def adjust_stock?
      admin_user?
    end
  end
end
```

**Checklist** :
- [x] Créer fichier `app/policies/admin_panel/inventory_policy.rb`
- [x] Tester autorisations inventory

---

## ✅ BasePolicy (VÉRIFIER)

**Fichier** : `app/policies/admin_panel/base_policy.rb`

**Code attendu** :
```ruby
module AdminPanel
  class BasePolicy
    attr_reader :user, :record
    
    def initialize(user, record)
      @user = user
      @record = record
    end
    
    def admin_user?
      user.present? && (user.admin? || user.superadmin?)
    end
    
    # Méthodes par défaut (peuvent être surchargées)
    def index?
      admin_user?
    end
    
    def show?
      admin_user?
    end
    
    def create?
      admin_user?
    end
    
    def update?
      admin_user?
    end
    
    def destroy?
      admin_user?
    end
  end
end
```

**Checklist** :
- [ ] Vérifier BasePolicy existe
- [ ] Vérifier méthode `admin_user?`
- [ ] Vérifier méthodes par défaut

---

## ✅ Checklist Globale

### **Phase 2 (Semaine 2)** ✅
- [x] Vérifier ProductPolicy
- [x] Créer ProductVariantPolicy
- [x] Créer InventoryPolicy
- [x] Vérifier BasePolicy
- [x] Tester toutes les autorisations

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
