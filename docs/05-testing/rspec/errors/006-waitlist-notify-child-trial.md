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

---

## Statut

À ANALYSER
