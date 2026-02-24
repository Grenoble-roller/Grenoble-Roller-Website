# Erreur 007 : Initiation registration Free Trial et member_participants_count

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 1  
**Catégorie** : Requests initiation registration

---

## Informations Générales

- **Fichier** : spec/requests/initiation_registration_spec.rb
- **Lignes** : 109, 1407, 1437
- **Commande** : docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/initiation_registration_spec.rb:109

---

## Erreur

- 109 : Free Trial Second. Attendu redirect vers initiation_path(second_initiation), recu root_path.
- 1407 : Famille non-adherente decouverte. member_participants_count attendu 2, recu 1.
- 1437 : Melange adherents/non-adherents. Attendu 3, recu 2.

---

## Analyse

Redirect 2e essai et comptage member_participants_count. Controller ou definition du comptage.

---

## Solutions Proposées

1. Verifier redirect quand essai deja utilise.
2. Verifier definition member_participants_count et setup specs famille.

---

## Statut

À ANALYSER
