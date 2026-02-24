# Erreur #003 : AdminPanel::Event::InitiationPolicy – index? (true) et update? (false)

**Date d'analyse** : 2026-02-24  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Policies – admin panel initiations

---

## 📋 Informations Générales

- **Fichier test** : `spec/policies/admin_panel/event/initiation_policy_spec.rb`
- **Lignes** : 18 (index?), 120 (update?)
- **Tests** : `index? when user is initiation (level 30) is expected to equal true` ; `update? when user is organizer (level 40) is expected to equal false`
- **Commande pour reproduire** :
  ```bash
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/policies/admin_panel/event/initiation_policy_spec.rb:18
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/policies/admin_panel/event/initiation_policy_spec.rb:120
  ```

---

## 🔴 Erreur

- **Ligne 18** : `expected to equal true` (valeur reçue non true pour index? avec user level 30).
- **Ligne 120** : `expected to equal false` (valeur reçue non false pour update? avec user level 40).

Message exact à recopier après relance (possiblement lié à un setup commun : création d’initiation → job, ou scope/record).

---

## 🔍 Analyse

### Constats
- ✅ Les rôles (initiation level 30, organizer level 40) sont cohérents avec le reste de l’app.
- ❌ La policy retourne une valeur différente de ce que le spec attend pour ces rôles.
- 🔍 Vérifier si le setup du spec crée une initiation (callback job) ou modifie le `record`/`scope` de façon inattendue.

### Cause Probable
- Règles de la policy (AdminPanel::Event::InitiationPolicy) pour `index?` et `update?` ne correspondent pas aux attentes du spec (niveau requis, rôle organizer vs initiation).
- Ou le `record`/contexte passé à la policy dans le spec n’est pas celui attendu.

### Code Actuel
À compléter : `app/policies/admin_panel/event/initiation_policy.rb` (méthodes `index?`, `update?`), et le setup du spec (user, role, record).

---

## 💡 Solutions Proposées

### Solution 1 : Aligner la policy (app)
Si la règle métier veut que level 30 (initiation) puisse voir la liste (index?) et que level 40 (organizer) ne puisse pas update, adapter les conditions dans la policy pour retourner true/false en conséquence.

### Solution 2 : Aligner le spec (test)
Si la règle métier a changé (ex. organizer peut update, initiation ne peut pas index?), mettre à jour les attentes du spec (`expect(...).to eq(false)` / `true`) et le libellé des exemples.

---

## 🎯 Type de Problème

À trancher après lecture de la policy : **PROBLÈME DE TEST** (attentes obsolètes) ou **PROBLÈME DE LOGIQUE** (policy incorrecte).

---

## 📊 Statut

⏳ **À ANALYSER** – Relancer les deux exemples, copier l’erreur exacte, puis comparer avec la logique dans `InitiationPolicy`.

---

## 🔗 Erreurs Similaires

- [004-admin-initiations-redirect.md](004-admin-initiations-redirect.md) (initiations_spec 54, 137, 170 ; base_controller 18).

---

## 📝 Notes

- Voir [spec-failures-audit.md](../spec-failures-audit.md) liste #5, #6, #7.

---

## ✅ Actions à Effectuer

1. [ ] Relancer les specs :18 et :120 et coller le message d’erreur complet.
2. [ ] Lire `app/policies/admin_panel/event/initiation_policy.rb` pour index? et update?.
3. [ ] Décider : corriger la policy ou les attentes du spec, puis appliquer.
4. [ ] Mettre à jour le statut dans [README.md](../README.md).
