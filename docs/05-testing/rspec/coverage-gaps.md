# Lacunes de couverture des specs (prod)

Document généré pour identifier ce qui **n’est pas couvert** par les specs actuels et **devrait l’être** pour sécuriser la prod (auth/authz, chemins critiques, règles métier).

---

## 1. Contrôleurs / routes sans request spec

| Zone | Fichier / route | Priorité | Commentaire |
|------|-----------------|----------|-------------|
| **Health** | `GET /health` | Haute | Monitoring / load balancer. Vérifier 200 vs 503, JSON (database, migrations). |
| **Admin – Maintenance** | `PATCH /admin-panel/maintenance/toggle` | Haute | Réservé superadmin. Vérifier authz (MaintenancePolicy) et effet enable/disable. |
| **Admin – Mail logs** | `GET /admin-panel/mail-logs`, `GET .../:id` | Moyenne | Superadmin uniquement. Authz + accès liste/détail. |
| **Admin – Homepage carousels** | CRUD + publish/unpublish, move_up, move_down, reorder | Moyenne | Request spec partiel (index, new, auth). Manquent : create, update, destroy, publish, unpublish, move_up, move_down, reorder. Niveau ORGANIZER+. |
| **Admin – Initiations (actions manquantes)** | `convert_waitlist`, `notify_waitlist`, `toggle_volunteer`, `return_material` | Haute | Actions métier sensibles ; actuellement seuls index/show/presences/update_presences sont testés. |
| **Confirmations (Devise)** | `ConfirmationsController` (new, create, show) | Moyenne | Renvoi email confirmation, limite de taux, anti-énumération. |
| **Pages légales** | `LegalPagesController` (mentions, RGPD, CGV, CGU, FAQ) | Basse | GET statiques ; utile en smoke (200 + contenu minimal). |
| **Cookie consent** | `CookieConsentController` (preferences, accept, reject, update) | Basse | RGPD ; vérifier accept/reject et persistance. |

---

## 2. Actions HTTP non couvertes (dans des contrôleurs déjà partiellement testés)

| Contrôleur | Action(s) | Priorité | Commentaire |
|------------|-----------|----------|-------------|
| **Orders** | `PATCH /orders/:id/cancel` | Haute | Annulation par l’utilisateur ; libération du stock, statuts (pending vs paid). |
| **Orders** | `POST /orders/:id/check_payment` | Moyenne | Vérification HelloAsso côté user ; auth + redirection. |
| **Admin – Memberships** | `POST /admin-panel/memberships/:id/check_payment` | Moyenne | Vérification paiement côté admin ; authz (check_payment?). |

---

## 3. Modèles sans spec (ou spec vide)

| Model | Priorité | Commentaire |
|-------|----------|-------------|
| **RollerStock** | Moyenne | Spec présent mais vide. Validations (size, quantity, is_active), scopes (active, available), `available?`, `out_of_stock?`, `size_with_stock`. |
| **MaintenanceMode** | Basse | Classe non-AR (cache). `enabled?`, `enable!`, `disable!`, `toggle!`, `status`. Utile si maintenance est critique. |
| **HomepageCarousel** | Basse | Validations, scopes (published, active, ordered). Optionnel. |
| **EventLoopRoute** | Basse | Si utilisé pour logique métier (parcours, boucles), ajouter des exemples ciblés. |

---

## 4. Policies sans spec

| Policy | Priorité | Commentaire |
|--------|----------|-------------|
| **AdminPanel::MaintenancePolicy** | Haute | Restriction superadmin ; à tester pour toggle. |
| **AdminPanel::HomepageCarouselPolicy** | Moyenne | Niveau ORGANIZER+ ; index/show/create/update/destroy. |
| **AdminPanel::ProductVariantPolicy** | Moyenne | Droits sur les variantes (bulk_edit, toggle_status, etc.). |

*Note : Mail logs* — vérifier si une policy dédiée existe ; sinon gérée par BaseController / niveau superadmin.

---

## 5. Jobs / services non couverts

À vérifier au besoin (parcours rapide) :

- **MissionControl::Jobs** : monté sous `/admin-panel/jobs` ; accès réservé (superadmin ?) — à confirmer et tester en request si critique.
- Autres jobs (outre `ReturnRollerStockJob`, `EventReminderJob`, `InitiationParticipantsReportJob`) : couvrir si logique métier importante.

---

## 6. Synthèse par priorité

### À faire en priorité (prod / sécurité)

1. **Health** : request spec `GET /health` (200 OK, 503 si migrations en attente ou DB down).
2. **Admin maintenance** : request spec `PATCH /admin-panel/maintenance/toggle` (superadmin OK, non-superadmin refusé).
3. **Admin initiations** : request specs pour `convert_waitlist`, `notify_waitlist`, `toggle_volunteer`, `return_material` (authz + comportement de base).
4. **Orders** : request spec `PATCH /orders/:id/cancel` (auth, statuts autorisés, libération stock, message si déjà payé).
5. **MaintenancePolicy** : policy spec (superadmin autorisé, autres refusés).

### Ensuite (moyenne priorité)

6. **Admin mail_logs** : request specs index/show + authz superadmin.
7. **Admin homepage_carousels** : request specs CRUD + actions custom (publish, reorder, etc.) + authz.
8. **ConfirmationsController** : request specs (new, create, show) — rate limit, anti-énumération.
9. **Orders check_payment** (user) et **Admin memberships check_payment**.
10. **RollerStock** : model spec (validations, scopes, `available?`, `out_of_stock?`).
11. **AdminPanel::HomepageCarouselPolicy** et **ProductVariantPolicy** : policy specs.

### Optionnel (basse priorité)

12. **Pages légales** : smoke GET (200 + contenu attendu).
13. **Cookie consent** : accept/reject/update.
14. **MaintenanceMode** (unit), **HomepageCarousel** (model), **EventLoopRoute** si logique métier.

---

## 7. Références

- Méthode et fiches d’erreurs : [METHODE.md](METHODE.md), [errors/](errors/), [README.md](README.md).
- Audit des échecs / archive : [spec-failures-audit.md](spec-failures-audit.md).
- Bonnes pratiques (vues, priorisation) : pas de view spec pour chaque template ; prioriser request + model + feature sur chemins critiques.
