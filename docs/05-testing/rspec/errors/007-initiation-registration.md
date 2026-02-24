# Erreur 007 : Initiation registration Free Trial et member_participants_count

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 1  
**Catégorie** : Requests initiation registration

---

## Informations Générales

- **Fichier** : spec/requests/initiation_registration_spec.rb
- **Lignes** : 109, 1407, 1437
- **Commande** : `bundle exec rspec spec/requests/initiation_registration_spec.rb:109 spec/requests/initiation_registration_spec.rb:1407 spec/requests/initiation_registration_spec.rb:1437`

---

## Erreur

- 109 : Free Trial Second. Attendu redirect vers initiation_path(second_initiation), reçu root_path.
- 1407 : Famille non-adhérente découverte. member_participants_count attendu 2, reçu 1.
- 1437 : Mélange adhérents/non-adhérents. Attendu 3, reçu 2.

---

## Analyse

1. **Redirect 2e essai** : La policy `Event::InitiationPolicy#attend?` renvoyait false pour un parent non-adhérent ayant déjà utilisé son essai gratuit, ce qui déclenchait `Pundit::NotAuthorizedError` et la redirection générique vers root dans `ApplicationController#user_not_authorized`. Le contrôleur avait déjà la logique (l.124–132) pour rediriger vers `initiation_path(@initiation)` avec le message attendu.
2. **member_participants_count** : Pour le parent (sans child_membership_id), seul `memberships.active_now.where(is_child_membership: false)` était pris en compte. Le spec attend que le parent compte comme membre s’il a au moins une adhésion **enfant** active (« parent via adhésion enfant »).

---

## Solutions Appliquées

1. **Policy** (`app/policies/event/initiation_policy.rb`) : Pour le parent non-adhérent quand `allow_non_member_discovery` est false, la policy retourne désormais `true` au lieu de vérifier l’essai gratuit. Le contrôleur `Initiations::AttendancesController` gère le cas « essai déjà utilisé » et redirige vers `initiation_path(@initiation)` avec « Vous avez déjà utilisé votre essai gratuit » et « Une adhésion est maintenant requise ».
2. **Modèle** (`app/models/event/initiation.rb`) : Dans `member_participants_count`, pour le parent, on considère membre si adhésion adulte **ou** au moins une adhésion enfant active :  
   `attendance.user.memberships.active_now.where(is_child_membership: false).exists? || attendance.user.memberships.active_now.where(is_child_membership: true).exists?`

---

## Statut

✅ RÉSOLU
