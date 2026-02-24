# Erreur 008 : Memberships renouvellement enfant et GET new type=child

**Date d'analyse** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Requests memberships

---

## Informations Générales

- **Fichier** : spec/requests/memberships_spec.rb
- **Lignes** : 293, 573, 607 (ex. 586, 620 après décalage)
- **Commande** : `bundle exec rspec spec/requests/memberships_spec.rb:293 spec/requests/memberships_spec.rb:586 spec/requests/memberships_spec.rb:620`

---

## Erreur

- 293 : Renouvellement enfant avec adhésion déjà existante pour la saison. Membership.count augmentait (nouvelle adhésion créée au lieu de bloquer).
- 573 / 586 : GET /memberships/new?type=child&renew_from=… — attendu 200, reçu 302 (profil parent incomplet) ; puis message « Votre enfant a droit à un essai gratuit » affiché alors qu’il a déjà été utilisé (old_membership non considérée expirée).
- 607 / 620 : GET idem — 302 puis après correction 200 avec message essai gratuit affiché.

---

## Analyse

1. **Renouvellement** : Le contrôleur devait bloquer en tête de `create` quand `renew_from` est présent et qu’un même enfant a déjà une adhésion (active/pending/trial) pour la saison courante, sans créer de nouvelle adhésion.
2. **GET new type=child** : Le before_action `ensure_parent_profile_complete_for_child` redirige (302) si le profil parent n’est pas complet. Les specs utilisaient un `user` sans phone/address/postal_code/city/date_of_birth. De plus, pour le renouvellement, `@old_membership` n’était défini que si `old_membership.expired?` est true ; la factory avec `status: :expired` garde `end_date` par défaut (future), donc `expired?` était false et `@child_has_used_trial` n’était jamais calculé.

---

## Solutions Appliquées

1. **MembershipsController#create** : En tête du bloc `renew_from`, vérification explicite : même enfant (prénom, nom, date de naissance) avec une adhésion enfant pour la saison courante (active/pending/trial). Si trouvée → `redirect_to membership_path(existing_membership)` avec notice « Une adhésion existe déjà pour … », sans appeler `renew_child_membership_from_form`.
2. **Spec 293** : Utilisation de `expect { post ... }.not_to change(Membership, :count)` et création explicite des deux adhésions (expired + current) avant le post pour éviter l’effet de l’ordre des `let` sur le comptage.
3. **Spec GET new (573/607)** : Utilisation d’un `user_with_complete_profile` (first_name, last_name, phone, address, postal_code, city, date_of_birth) pour éviter la 302 ; pour les deux exemples « essai déjà utilisé » et « essai pas encore utilisé », création de `old_membership` avec `start_date` et `end_date` dans le passé (ex. 2024-09-01 / 2025-08-31) pour que `expired?` soit true et que le contrôleur pose `@old_membership` et calcule `@child_has_used_trial`.
4. **MembershipsController#new (child)** : Calcul de `@child_has_used_trial` pour `@old_membership` via les adhésions enfants de même identité (prénom, nom, date de naissance) et existence d’une attendance active avec `free_trial_used: true` pour l’un de ces child_membership_id (requête avec sous-requête sur les id).

---

## Impact vues

**Aucune modification des vues.** Les vues `memberships/child_form.html.erb` et `memberships/adult_form.html.erb` utilisaient déjà `@old_membership` et `@child_has_used_trial` ; seuls le contrôleur et les specs ont été modifiés pour alimenter correctement ces variables.

---

## Vérification que tout fonctionne

1. **Exemples ciblés (fiche 008)**  
   ```bash
   bundle exec rspec spec/requests/memberships_spec.rb:293 spec/requests/memberships_spec.rb:586 spec/requests/memberships_spec.rb:620
   ```

2. **Fichier memberships complet** (régression sur les autres exemples)  
   ```bash
   bundle exec rspec spec/requests/memberships_spec.rb
   ```

3. **Suite complète** (optionnel)  
   ```bash
   bundle exec rspec spec/
   ```

4. **Test manuel** (optionnel) : connecté en tant qu’utilisateur avec profil parent complet, aller sur « Nouvelle adhésion » → Enfant, puis renouveler une adhésion expirée ; vérifier que le message « Votre enfant a droit à un essai gratuit » n’apparaît pas si l’enfant a déjà utilisé son essai, et qu’une tentative de renouvellement alors qu’une adhésion courante existe redirige vers cette adhésion avec le message « Une adhésion existe déjà ».

---

## Statut

✅ RÉSOLU
