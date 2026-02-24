# Erreur 004 : Admin initiations 302 et redirect

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Admin panel initiations

---

## Informations Générales

- **Fichiers** : spec/requests/admin_panel/initiations_spec.rb (54, 137, 170), base_controller_spec.rb (18)
- **Commande** : docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/admin_panel/initiations_spec.rb:54

---

## Erreur

- Ligne 54 : expected success (2xx) but was 302 (GET initiations, user initiation level 30).
- Lignes 137, 170 : Expected redirect to admin_panel_root_path but was redirect to admin-panel/initiations (organizer level 40).

---

## Analyse

Comportement redirect ou autorisation différent des attentes. Controller ou policy à comparer au spec.

---

## Solutions Proposées

1. App : aligner redirect (organizer non autorisé vers root admin).
2. Test : mettre à jour redirect_to attendu si la règle est de rediriger vers initiations.

---

## Type de Problème

À trancher.

---

## Statut

À ANALYSER

---

## Erreurs Similaires

Fiche 003 (InitiationPolicy).
