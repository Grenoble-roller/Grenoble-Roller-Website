# Erreur 011 : AdminPanel::Payments – redirect après DELETE non autorisé

**Date** : 2026-02-24  
**Priorité** : Priorité 2  
**Catégorie** : Requests – admin panel payments

---

## Informations

- **Fichier** : `spec/requests/admin_panel/payments_spec.rb`
- **Ligne** : 176
- **Exemple** : `redirects to admin panel initiations with alert` (DELETE payment en tant qu’admin level 60)

---

## Erreur

`Expected response to be a redirect to <.../admin-panel/initiations> but was a redirect to <.../admin-panel>`.  
Le spec attendait `admin_panel_initiations_path`, l’app redirige vers `admin_panel_root_path` (comportement unifié de la fiche 004 : `user_not_authorized` dans `AdminPanel::BaseController` → `admin_panel_root_path`).

---

## Solution appliquée

**Spec** : aligner l’assertion sur le comportement actuel.  
- `redirect_to(admin_panel_initiations_path)` → `redirect_to(admin_panel_root_path)`  
- Libellé de l’exemple : `redirects to admin panel root with alert`.

---

## Statut

✅ RÉSOLU
