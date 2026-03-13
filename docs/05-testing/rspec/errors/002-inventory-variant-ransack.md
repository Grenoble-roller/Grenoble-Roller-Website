# Erreur #002 : Inventory – variant déjà utilisé + Ransack

**Date d'analyse** : 2026-02-24  
**Priorité** : 🔴 Priorité 1  
**Catégorie** : Admin panel – inventaire

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/admin_panel/inventory_spec.rb`
- **Lignes** : 20, 28, 36, 67, 72, 82, 112, 127, 138, 153
- **Commande pour reproduire** :
  ```bash
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/admin_panel/inventory_spec.rb:20
  ```

---

## 🔴 Erreur

**A** – `ActiveRecord::RecordInvalid: Product variant est déjà utilisé` (create(:inventory, product_variant: variant)).

**B** – `Ransack needs Inventory attributes explicitly allowlisted` dans transfers.html.erb (ransackable_attributes manquant sur Inventory).

---

## 🔍 Analyse

- Un même variant est réutilisé pour plusieurs inventory alors qu’il y a unicité (ou 1-1).
- Le modèle Inventory n’a pas de `ransackable_attributes` alors que la vue transfers utilise Ransack.

---

## 💡 Solutions Proposées

1. **Test** : Créer un variant (ou inventory) distinct par exemple pour éviter la contrainte d’unicité.
2. **App** : Ajouter dans `app/models/inventory.rb` : `def self.ransackable_attributes(auth_object = nil)` avec les attributs autorisés.

---

## 🎯 Type de Problème

- Variant : ❌ **PROBLÈME DE TEST**
- Ransack : ⚠️ **PROBLÈME DE LOGIQUE** (ou oubli app)

---

## 📊 Statut

🟢 **RÉSOLU** – 14 examples, 0 failures (inventory_spec.rb).

---

## Solutions appliquées

1. **sign_in → login_user** dans inventory_spec.rb (comme fiche 001).
2. **App – Ransack** : ajout de `ransackable_attributes` et `ransackable_associations` dans `app/models/inventory.rb`.
3. **Test – variant déjà utilisé** : `ProductVariant` a un `after_create :create_inventory_record`. Le spec utilise maintenant `variant.inventory` (et `variant.inventory.update!(...)`) au lieu de `create(:inventory, product_variant: variant)`. Pour @low_stock et @out_of_stock, utilisation de `create(:product_variant, is_active: true)` car le controller filtre par `is_active: true`.
4. **App – InventoryService** : `Current.user` provoquait `NameError` en test (constant non définie). Passage à `user = (defined?(::Current) && ::Current.respond_to?(:user)) ? ::Current.user : nil` avant d’appeler `move_stock`.

---

## 🔗 Erreurs Similaires

- [009-products-variant-options.md](009-products-variant-options.md)

---

## ✅ Actions à Effectuer

1. [x] Vérifier contrainte product_variant_id (unicité + callback ProductVariant).
2. [x] Adapter le spec (utiliser variant.inventory, is_active: true).
3. [x] Ajouter ransackable_attributes/associations dans Inventory.
4. [x] Corriger InventoryService pour Current en test.
5. [x] Mettre à jour [README.md](../README.md).

**Impact vues (procédure)** : Aucun fichier de vue modifié. La vue `admin_panel/inventory/transfers.html.erb` utilisait déjà Ransack ; l’allowlist sur le modèle Inventory permet au filtre de fonctionner sans changer le rendu. Page inventaire et transfers : comportement identique ou corrigé (filtres OK).
