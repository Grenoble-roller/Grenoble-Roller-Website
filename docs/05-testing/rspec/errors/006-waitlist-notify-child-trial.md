# Erreur 006 : WaitlistEntry notify child free trial

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Modeles waitlist

---

## Informations Générales

- **Fichier** : spec/models/waitlist_entry_spec.rb
- **Ligne** : 40
- **Test** : notify! does not create attendance if child free trial already used
- **Commande** : docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/models/waitlist_entry_spec.rb:40

---

## Erreur

Comportement attendu : ne pas creer attendance si enfant a deja utilise essai gratuit. Assertion echoue.

---

## Analyse

Logique WaitlistEntry notify! et condition essai gratuit enfant. Spec ou modele.

### Modifications appliquées
- **WaitlistEntry#notify!** : après `build_pending_attendance`, si `attendance.free_trial_used` et `attendance.child_membership_id` sont présents, vérifier que l’enfant n’a pas déjà une attendance active avec `free_trial_used`. Si oui, retourner `false` sans créer d’attendance ni passer l’entry en `notified`.

---

## Statut

✅ **RÉSOLU** – Dans `WaitlistEntry#notify!`, avant de sauvegarder l’attendance, vérification ajoutée : si l’inscription utilise l’essai gratuit pour un enfant (`free_trial_used` + `child_membership_id`) et que cet enfant a déjà une attendance active avec `free_trial_used`, on ne crée pas l’attendance et on retourne `false`. Évite la violation de la contrainte unique `index_attendances_unique_free_trial_child_active` et respecte la règle métier « un seul essai gratuit par enfant ». 8 examples, 0 failures.
