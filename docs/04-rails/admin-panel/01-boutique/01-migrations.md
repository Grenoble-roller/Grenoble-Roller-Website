# 🗄️ MIGRATIONS - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 1 | **Semaine** : 1

---

## 📋 Description

Migrations nécessaires pour le système d'inventaire et la gestion des images via Active Storage.

---

## ✅ Migration 1 : Table Inventories

**Fichier** : `db/migrate/20251224032419_create_inventories.rb`

**Code exact** :
```ruby
class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :product_variant, null: false, foreign_key: true, index: { unique: true }
      t.integer :stock_qty, default: 0, null: false
      t.integer :reserved_qty, default: 0, null: false
      t.timestamps
    end
  end
end
```

**Checklist** :
- [x] Créer fichier migration
- [x] Exécuter `rails db:migrate`
- [x] Vérifier table créée dans schema.rb
- [x] Corriger index unique (utiliser `index: { unique: true }` dans `t.references`)

---

## ✅ Migration 2 : Table InventoryMovements

**Fichier** : `db/migrate/20251224032423_create_inventory_movements.rb`

**Code exact** :
```ruby
class CreateInventoryMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :quantity, null: false
      t.string :reason, null: false
      t.string :reference
      t.integer :before_qty, null: false
      t.timestamps
    end
    
    add_index :inventory_movements, :created_at
  end
end
```

**Note** : L'index sur `inventory_id` est créé automatiquement par `t.references`, donc pas besoin de `add_index` explicite.

**Checklist** :
- [x] Créer fichier migration (`20251224032423_create_inventory_movements.rb`)
- [x] Exécuter `rails db:migrate`
- [x] Vérifier table créée dans schema.rb
- [x] Corriger index (retirer `add_index` redondant car `t.references` crée déjà l'index)

---

## ✅ Migration 3 : Migration image_url vers Active Storage

**Fichier** : `db/migrate/YYYYMMDDHHMMSS_migrate_variant_images_to_active_storage.rb`

**Code exact** :
```ruby
class MigrateVariantImagesToActiveStorage < ActiveRecord::Migration[8.1]
  def up
    ProductVariant.find_each do |variant|
      next if variant.image_url.blank?
      
      begin
        # Télécharger image depuis URL
        uri = URI.parse(variant.image_url)
        file = uri.open
        
        # Attacher via Active Storage
        variant.images.attach(
          io: file,
          filename: File.basename(uri.path),
          content_type: 'image/jpeg'
        )
        
        Rails.logger.info "✅ Variant #{variant.id} : Image migrée"
      rescue => e
        Rails.logger.error "❌ Variant #{variant.id} : Erreur migration image - #{e.message}"
      end
    end
  end
  
  def down
    # Pas de rollback facile (destructif)
    # Les images Active Storage restent attachées
  end
end
```

**Checklist** :
- [ ] Créer fichier migration
- [ ] Tester sur staging avec quelques variants
- [ ] Exécuter `rails db:migrate` en production
- [ ] Vérifier images attachées dans Active Storage
- [ ] Optionnel : Supprimer colonne `image_url` après vérification

---

## ✅ Migration 4 : Ajouter parent_id aux Categories (Optionnel)

**Fichier** : `db/migrate/YYYYMMDDHHMMSS_add_parent_id_to_product_categories.rb`

**Code exact** :
```ruby
class AddParentIdToProductCategories < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_categories, :parent, null: true, foreign_key: { to_table: :product_categories }
    add_index :product_categories, :parent_id
  end
end
```

**Checklist** :
- [ ] Créer fichier migration (si hiérarchie nécessaire)
- [ ] Exécuter `rails db:migrate`
- [ ] Vérifier colonne ajoutée

---

## 📊 Ordre d'Exécution

1. **Migration 1** : Inventories (base)
2. **Migration 2** : InventoryMovements (dépend de Inventories)
3. **Migration 3** : Migration images (peut être fait après)
4. **Migration 4** : Categories parent_id (optionnel, peut être fait plus tard)

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)** ✅
- [x] Migration 1 : Inventories (avec correction index unique)
- [x] Migration 2 : InventoryMovements (avec correction index)
- [ ] Migration 3 : Migration images (optionnel, à faire si nécessaire)
- [ ] Migration 4 : Categories parent_id (optionnel, si hiérarchie nécessaire)

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
