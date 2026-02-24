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
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/products_spec.rb:41
  ```

---

## 🔴 Erreur

`ActiveRecord::RecordInvalid: La validation a échoué : Les variantes doivent avoir des options de catégorisation` lors de `create(:product_variant, product: product, is_active: false)`.

---

## 🔍 Analyse

La factory ou le spec crée une variante sans les options de catégorisation requises par le modèle ProductVariant.

---

## 💡 Solutions Proposées

1. **Test** : Donner à la variante les options requises (option_types/option_values) dans le spec ou la factory.
2. **App** : Si la validation est trop stricte pour certains cas (ex. variante inactive), adapter la validation ou les attributs allowlist.

---

## 🎯 Type de Problème

Souvent ❌ **PROBLÈME DE TEST** (factory/setup incomplet).

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

- [002-inventory-variant-ransack.md](002-inventory-variant-ransack.md)
