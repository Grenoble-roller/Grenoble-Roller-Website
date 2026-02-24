# Erreur 008 : Memberships renouvellement enfant et GET new type=child

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Requests memberships

---

## Informations Générales

- **Fichier** : spec/requests/memberships_spec.rb
- **Lignes** : 293, 573, 607
- **Commande** : docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/memberships_spec.rb:293

---

## Erreur

- 293 : Renouvellement enfant avec adhesion deja existante saison. Membership.count attendu 1, recu 2.
- 573, 607 : GET /memberships/new?type=child. Attendu 200, recu 302 (essai deja utilise / pas encore utilise).

---

## Analyse

Regle renouvellement (bloquer si deja adhesion) et conditions acces formulaire enfant. Controller ou spec.

---

## Statut

À ANALYSER
