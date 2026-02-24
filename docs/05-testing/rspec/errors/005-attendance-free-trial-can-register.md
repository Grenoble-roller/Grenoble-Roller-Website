# Erreur 005 : Attendance free_trial et can_register_to_initiation

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Modeles attendance

---

## Informations Générales

- **Fichier** : spec/models/attendance_spec.rb
- **Lignes** : 321, 345, 438
- **Commande** : docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/models/attendance_spec.rb:321

---

## Erreur

- 321 : free_trial_used validation prevents bypassing for trial child.
- 345 : prevents registration without free trial when JS disabled.
- 438 : can_register_to_initiation with child membership allows registration.

---

## Analyse

Validations et logique inscription initiation (essai gratuit, adhesion enfant). Setup ou regle metier.

---

## Solutions Proposées

Lire spec et modele Attendance, verifier attentes vs regles metier.

---

## Statut

À ANALYSER
