# Erreur 012 : Initiation registration – 2e essai gratuit, redirect attendu

**Date** : 2026-02-24  
**Priorité** : Priorité 1  
**Catégorie** : Requests – initiation registration

---

## Informations

- **Fichier** : `spec/requests/initiation_registration_spec.rb`
- **Ligne** : 72
- **Exemple** : `prevents user from using free trial twice` (POST avec `use_free_trial: "1"` sur une 2e initiation)

---

## Erreur

`Expected response to be a redirect to <.../> but was a redirect to <.../initiations/Vw4XaT4w>`.  
Le spec attendait `redirect_to(root_path)` (ancien comportement : la policy bloquait → `NotAuthorizedError` → `ApplicationController` → root).  
Depuis la fiche 007, le contrôleur gère lui‑même le cas « essai gratuit déjà utilisé » et redirige vers `initiation_path(second_initiation)` avec le message approprié.

---

## Solution appliquée

**Spec** : aligner sur le comportement actuel.  
- `expect(response).to redirect_to(root_path)` → `expect(response).to redirect_to(initiation_path(second_initiation))`  
- Ajout de `expect(flash[:alert]).to include("Vous avez déjà utilisé votre essai gratuit")` pour garder la couverture du message.

---

## Statut

✅ RÉSOLU
