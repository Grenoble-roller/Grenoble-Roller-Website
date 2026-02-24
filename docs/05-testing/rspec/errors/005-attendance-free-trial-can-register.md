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

### Modifications appliquées
- **Attendance** : message d’erreur `free_trial_used` pour enfant trial/pending → « L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante. »
- **attendance_spec** : contexte « when user has child membership » → créer la membership en `let!(:child_membership)` et appeler `build_attendance(..., child_membership_id: child_membership.id)` pour tester l’inscription **de l’enfant** (adhésion enfant active = pas d’essai gratuit requis).

---

## Statut

✅ **RÉSOLU** – 1) Message de validation `free_trial_used` aligné sur le spec/doc : « L'essai gratuit est obligatoire pour les **enfants non adhérents**. Veuillez cocher la case correspondante. » 2) Spec « allows registration with child membership » : l’inscription doit être **pour l’enfant** (child_membership_id) ; le spec passait uniquement user/event donc l’attendance était pour le parent (sans adhésion adulte). Ajout de `let!(:child_membership)` et passage de `child_membership_id` dans `build_attendance`. 37 examples, 0 failures.
