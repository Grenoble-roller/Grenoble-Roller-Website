# Erreur #009 : Products – variantes options de catégorisation

**Date d'analyse** : 2026-02-24  
**Priorité** : 🟡 Priorité 3  
**Catégorie** : Requests – products

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/products_spec.rb`
- **Ligne** : 41
- **Test** : `GET /products/:id loads active variants`
- **Commande pour reproduire** :
  ```bash
  bundle exec rspec spec/requests/products_spec.rb:41
  ```

---

## 🔴 Erreur

`ActiveRecord::RecordInvalid: La validation a échoué : Les variantes doivent avoir des options de catégorisation` lors de `create(:product_variant, product: product, is_active: false)` (ou avec plusieurs variantes).

---

## 🔍 Analyse

1. **Options de catégorisation** : `ProductVariant` exige que chaque variante ait des `variant_option_values` lorsque le produit a plus d’une variante (`has_required_option_values`). La factory créait ces options en `after(:create)`, donc après la validation → échec à la sauvegarde.
2. **Option en `after(:build)`** : En construisant les `variant_option_values` en `after(:build)`, les enregistrements associés sont validés avec la variante ; `VariantOptionValue` exige `variant_id`, encore nil avant la persistance → validation des associés en échec.
3. **Contournement** : Utiliser le flag existant `@skip_option_validation` (déjà utilisé en seed) en `after(:build)`, puis créer les `VariantOptionValue` en `after(:create)` une fois la variante persistée.
4. **Image variante active** : Pour les variantes actives, une image est requise ; le fichier `spec/fixtures/files/test-image.jpg` est absent. La factory attache un blob minimal (StringIO) en fallback lorsque le fichier n’existe pas.

---

## 💡 Solutions Appliquées

- **Factory `product_variants.rb`** :
  - En `after(:build)` : `variant.instance_variable_set(:@skip_option_validation, true)` pour ne pas exiger d’options à la création.
  - En `after(:create)` : création de `OptionType` "size", `OptionValue` "Medium" si besoin, puis `VariantOptionValue.find_or_create_by!(variant: variant, option_value: size_value)` pour que chaque variante ait bien des options après création.
  - Pour les variantes actives : si `spec/fixtures/files/test-image.jpg` n’existe pas, attachement d’un blob minimal (`StringIO`) pour satisfaire `image_required_if_active`.

---

## 🎯 Type de Problème

**Problème de test** (factory/setup) : la factory ne respectait pas les validations du modèle (options après validation, image pour actif).

---

## Impact vues

Aucune modification des vues. Uniquement la factory et le flux de création des variantes en test.

---

## 📊 Statut

✅ **RÉSOLU**
