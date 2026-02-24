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

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

- [007-products-variant-options.md](007-products-variant-options.md)

---

## ✅ Actions à Effectuer

1. [ ] Vérifier contrainte product_variant_id sur Inventory.
2. [ ] Adapter le spec (un variant par cas).
3. [ ] Ajouter ransackable_attributes dans Inventory.
4. [ ] Mettre à jour [README.md](../README.md).
