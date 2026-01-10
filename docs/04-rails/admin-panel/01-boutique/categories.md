# 🛒 BOUTIQUE - Catégories

**Priorité** : 🟢 BASSE | **Phase** : 6+ | **Semaine** : 6+

---

## 📋 Description

Gestion des catégories produits avec hiérarchie optionnelle (parent-enfant).

**Fichier actuel** : `app/models/product_category.rb` (existe déjà)

**Note** : Hiérarchie catégories = Nice-to-have, pas critique pour le MVP.

---

## 🔧 Modifications Futures

### **Migration Hiérarchie**

**Fichier** : `db/migrate/YYYYMMDDHHMMSS_add_hierarchy_to_categories.rb`

```ruby
class AddHierarchyToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :product_categories, :parent_id, :bigint, null: true
    add_column :product_categories, :is_active, :boolean, default: true
    
    add_index :product_categories, :parent_id
    add_foreign_key :product_categories, :product_categories, column: :parent_id
  end
end
```

### **Modèle ProductCategory**

**Modifications** :
- Ajouter gem `acts_as_tree`
- Ajouter scopes `roots`, `active`
- Ajouter méthode `display_name` avec indentation

---

## ✅ Checklist (Optionnel)

- [ ] Migration hiérarchie (parent_id, is_active)
- [ ] Ajouter gem `acts_as_tree`
- [ ] Adapter modèle ProductCategory
- [ ] Adapter controller pour hiérarchie
- [ ] Vue tree view

---

**Priorité** : 🟢 BASSE - À faire dans 3+ mois si besoin réel

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
