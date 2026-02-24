# Audit des specs en échec

**Dernier run (conteneur dev, RAILS_ENV=test) :** 1054 exemples, **29 échecs**, 10 pending.

**Commande pour reproduire dans le conteneur :**
```bash
docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec spec/
```

**Objectif :** Pour chaque échec, analyser si la cause est un **problème de test** (setup, assertion obsolète, mock manquant) ou un **problème de logique applicative**. Pas de détournement sauf si nécessaire.

---

## Liste des 29 échecs (dernier run)

| # | Fichier | Ligne | Résumé |
|---|---------|-------|--------|
| 1 | `spec/models/attendance_spec.rb` | 321 | free_trial_used validation – prevents bypassing for trial child |
| 2 | `spec/models/attendance_spec.rb` | 345 | free_trial_used – prevents registration without free trial (JS disabled) |
| 3 | `spec/models/attendance_spec.rb` | 438 | can_register_to_initiation – allows registration with child membership |
| 4 | `spec/models/waitlist_entry_spec.rb` | 40 | notify! – does not create attendance if child free trial already used |
| 5 | `spec/policies/admin_panel/event/initiation_policy_spec.rb` | 18 | index? – initiation (level 30) expected true |
| 6 | `spec/policies/admin_panel/event/initiation_policy_spec.rb` | 120 | update? – organizer (level 40) expected false |
| 7 | `spec/requests/admin_panel/base_controller_spec.rb` | 18 | initiations (level 30) allows access |
| 8 | `spec/requests/admin_panel/dashboard_spec.rb` | 21 | GET /admin-panel displays dashboard (HTML diff) |
| 9 | `spec/requests/admin_panel/initiations_spec.rb` | 54 | GET initiations – initiation user returns success (302) |
| 10 | `spec/requests/admin_panel/initiations_spec.rb` | 137 | presences – organizer redirects not authorized (redirect vers initiations) |
| 11 | `spec/requests/admin_panel/initiations_spec.rb` | 170 | update_presences – organizer redirects not authorized |
| 12–21 | `spec/requests/admin_panel/inventory_spec.rb` | 20, 28, 36, 67, 72, 82, 112, 127, 138, 153 | Product variant déjà utilisé ; Ransack Inventory ransackable_attributes |
| 22 | `spec/requests/initiation_registration_spec.rb` | 109 | Free Trial Second – bloque 2e essai (redirect root au lieu de initiation) |
| 23 | `spec/requests/initiation_registration_spec.rb` | 1407 | Famille non-adhérente découverte – member_participants_count 2 vs 1 |
| 24 | `spec/requests/initiation_registration_spec.rb` | 1437 | Mélange adhérents/non-adhérents – member_participants_count 3 vs 2 |
| 25 | `spec/requests/memberships_spec.rb` | 293 | Renouvellement enfant – déjà adhésion saison → Membership.count 2 vs 1 |
| 26 | `spec/requests/memberships_spec.rb` | 573 | GET new?type=child – essai déjà utilisé → 302 au lieu de 200 |
| 27 | `spec/requests/memberships_spec.rb` | 607 | GET new?type=child – essai pas utilisé → 302 au lieu de 200 |
| 28 | `spec/requests/products_spec.rb` | 41 | GET /products/:id – variantes options catégorisation (product_variant factory) |
| 29 | `spec/requests/registrations_spec.rb` | 70 | sends welcome email – enqueued 0 (deliver_now vs deliver_later matcher) |

**Commandes pour relancer un échec isolé :**
```bash
docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec spec/requests/admin_panel/dashboard_spec.rb:21
```

**Fiches d’erreur (méthode)** : chaque type d’échec a une fiche dans [errors/](errors/) pour analyse et correction. Voir [README.md](README.md) pour l’index.

---

## 1. NotImplementedError – InitiationParticipantsReportJob (queue backend)

**Erreur :**
```text
InitiationParticipantsReportJob.set(wait_until: report_time).perform_later(id)
NotImplementedError: Use a queueing backend to enqueue jobs in the future.
```
**Cause probable :** En test, l’adapter Active Job `:test` ne gère pas `set(wait_until: ...)`. Le callback `schedule_participants_report` est exécuté à chaque création/mise à jour d’initiation publiée.

**À analyser :** Problème de **test** (env / adapter) ou **app** (callback déclenché en contexte test alors qu’il ne devrait pas) ?

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/mailers/event_mailer_spec.rb` | 381 | waitlist_spot_available when event is an initiation includes initiation-specific subject |
| `spec/mailers/event_mailer_spec.rb` | 411, 415, 420, 427, 438, 444, 453, 464, 476, 480 | initiation_participants_report (sujet, body, équipement, bénévole, etc.) |
| `spec/models/attendance_spec.rb` | 321, 345, 438 | free_trial_used / can_register_to_initiation |
| `spec/models/event/initiation_spec.rb` | 31, 42, 52, 64, 74, 90, 104, 116, 132, 140, 152, 162, 179, 189, 204, 224, 235, 252, 262, 282, 303, 328, 337 | full?, available_places, participants_count, volunteers_count, available_non_member_places, full_for_non_members?, scopes |
| `spec/models/waitlist_entry_spec.rb` | 18, 40, 76, 99, 134, 151, 178, 199 | notify!, convert_to_attendance!, validations |
| `spec/policies/admin_panel/event/initiation_policy_spec.rb` | 18–216 (tous) | index?, show?, create?, update?, destroy?, presences?, update_presences?, convert_waitlist?, notify_waitlist?, toggle_volunteer? |
| `spec/policies/event/initiation_policy_spec.rb` | 20, 39 | attend? (signed-in / guests) |
| `spec/requests/admin_panel/base_controller_spec.rb` | 18 | initiations (level >= 30) allows access |
| `spec/requests/admin_panel/dashboard_spec.rb` | 21 | GET /admin-panel displays dashboard |
| `spec/requests/admin_panel/events_spec.rb` | 31 | excludes initiations |
| `spec/requests/admin_panel/initiations_spec.rb` | 25, 42, 54, 86, 91, 102, 113, 126, 137, 155, 170 | index, show, presences, update_presences |
| `spec/requests/admin_panel/inventory_spec.rb` | 20, 28, 36, 67, 72, 82, 112, 127, 138, 153 | GET inventory, transfers, adjust_stock |
| `spec/requests/attendances_spec.rb` | 68, 74 | toggle_reminder (auth + toggle) |
| `spec/requests/initiation_registration_spec.rb` | 17, 47, 72, 109, 146, 187, 236, 291, 324, 362, 440, 465, 499, 527, 555, 593, 630, 666, 719, 757, 784, 840, 864, 905, 942, 971, 1007, 1049, 1087, 1110, 1135, 1163, 1188, 1213, 1254, 1275, 1300, 1339, 1366, 1407, 1437, 1470, 1505, 1536, 1570, 1597, 1622, 1654, 1681, 1717, 1761, 1819, 1863 | Tous les blocs initiation (duplicate, free trial, capacity, child membership, volontaires, non-member, draft, ICS, v4.0) |
| `spec/requests/initiations_spec.rb` | 10, 22, 51, 59, 110, 116 | index, show, ics, attendances |
| `spec/requests/waitlist_entries_spec.rb` | 70, 77, 94, 118, 149, 167, 192, 221, 272 | waitlist full + free trial (parent/child/pending) |

---

## 2. HTTP 429 (Rack::Attack – trop de tentatives)

**Erreur :** `expected status :unprocessable_entity (422) but was :too_many_requests (429)` — body « Trop de tentatives ».

**Cause :** Throttle Rack::Attack sur `/users` (inscriptions) et `/users/password` (reset). Plusieurs requêtes POST dans la même suite déclenchent la limite.

**À analyser :** Problème de **test** (limite trop basse ou pas de safelist en test) ou **app** (comportement voulu) ?

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/requests/registrations_spec.rb` | 122, 128, 133, 149, 155, 161, 178, 194, 210, 230 | without RGPD consent, invalid email, missing first_name, short password, missing skill_level, duplicate email |
| `spec/requests/passwords_spec.rb` | 59, 65, 77 | Turnstile échouée / sans token (422 attendu, 429 reçu) |

---

## 3. Registrations – redirect, jobs, User.count

**Erreurs observées :**
- Redirect : attendu `new_user_confirmation_path`, reçu `welcome_path`.
- Jobs : `have_enqueued_job` attendu avec `deliver_now`, app utilise `deliver_later`.
- `User.count` : attendu +1, resté à 0 (souvent en lien avec 429 ou redirect).

**À analyser :** Specs calés sur l’ancien comportement (confirmation page, deliver_now) vs **app** (welcome + deliver_later). **Test** à aligner ou **app** à revoir ?

| Fichier | Ligne | Description | Erreur résumée |
|---------|-------|-------------|----------------|
| `spec/requests/registrations_spec.rb` | 57 | redirects to confirmation page | redirect vers welcome_path |
| `spec/requests/registrations_spec.rb` | 70 | sends welcome email | enqueued 0 (deliver_later vs matcher ?) |
| `spec/requests/registrations_spec.rb` | 77 | sends confirmation email | enqueued 0 |
| `spec/requests/registrations_spec.rb` | 84 | creates user with correct attributes | User.count changé de 0 (pas créé) |
| `spec/requests/registrations_spec.rb` | 99 | allows immediate access (grace period) | idem User.count |

---

## 4. Waitlist refuse / decline – statut pending vs cancelled

**Erreur :** `expected status to have changed to "pending", but is now "cancelled"`.

**Cause :** Le modèle `WaitlistEntry#refuse!` met le statut à `cancelled`. Les specs attendaient `pending`.

**À analyser :** **Test** (assertion à mettre à jour vers `cancelled`) ou **app** (règles métier pour refus = pending vs cancelled) ?

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/requests/waitlist_entries_spec.rb` | 402 | refuses the waitlist entry |
| `spec/requests/waitlist_entries_spec.rb` | 466 | declines waitlist entry via GET (from email link) |

---

## 5. Orders – login_user (ArgumentError)

**Erreur :** `wrong number of arguments (given 2, expected 1)` dans `login_user` (request_authentication_helper.rb:7). Appel : `login_user(unconfirmed_user, confirm_user: false)`.

**Cause :** Le helper ne prenait qu’un argument ; un 2e (options) a été ajouté dans un spec.

**À analyser :** **Test** (signature du helper à étendre pour accepter des options) ou **app** (aucun impact). Déjà corrigé côté helper avec `**_options`.

---

## 6. Memberships

**Erreurs :**
- `expect(Membership.count).to eq(initial_count)` — got 2, expected 1 (renouvellement enfant alors qu’une adhésion existe déjà).
- `expect(response).to have_http_status(:success)` — got 302 (redirect au lieu de 200 sur GET /memberships/new?type=child).

**À analyser :** **Test** (données ou attente de statut) ou **app** (règles renouvellement / accès au formulaire enfant) ?

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/requests/memberships_spec.rb` | 293 | enfant a déjà une adhésion saison courante → bloque renouvellement |
| `spec/requests/memberships_spec.rb` | 573 | enfant a déjà utilisé essai gratuit → n'affiche PAS message essai gratuit |
| `spec/requests/memberships_spec.rb` | 607 | enfant n'a pas encore utilisé essai gratuit → affiche message essai gratuit |

---

## 7. Products – validation variantes

**Erreur :** `ActiveRecord::RecordInvalid: La validation a échoué : Les variantes doivent avoir des options de catégorisation` lors de `create(:product_variant, product: product, is_active: false)`.

**À analyser :** **Test** (factory ou données incomplètes) ou **app** (règle de validation trop stricte / inadaptée) ?

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/requests/products_spec.rb` | 41 | GET /products/:id loads active variants |

---

## 8. Passwords – current_user nil

**Erreur :** `undefined method 'current_user' for nil` (controller nil après 429).

**À analyser :** Conséquence du 429 (throttle) : le spec suppose 422 et un controller non nil. **Test** à isoler (éviter throttle) ou **app** (gestion de la réponse 429).

| Fichier | Ligne | Description du spec |
|---------|-------|----------------------|
| `spec/requests/passwords_spec.rb` | 65 | Turnstile échouée → ne crée pas de session utilisateur |

---

## 9. Policies AdminPanel::Event::InitiationPolicy

**Contexte :** Tous les exemples du fichier sont en échec. Cause possible : même **NotImplementedError** (création d’initiation dans le setup) ou erreur de policy (record/scope).

**À analyser :** Relancer un exemple isolé pour voir le message d’erreur exact (job vs policy).

| Fichier | Ligne | Description (résumé) |
|---------|-------|----------------------|
| `spec/policies/admin_panel/event/initiation_policy_spec.rb` | 18–216 | index?, show?, create?, update?, destroy?, presences?, update_presences?, convert_waitlist?, notify_waitlist?, toggle_volunteer? |

---

## 10. Récap par fichier (nombre d’échecs)

| Fichier | Nb échecs | Catégorie principale |
|---------|-----------|----------------------|
| `spec/requests/initiation_registration_spec.rb` | 57 | 1 (job) |
| `spec/requests/waitlist_entries_spec.rb` | 11 | 1 (job) + 2 (refuse/decline) |
| `spec/policies/admin_panel/event/initiation_policy_spec.rb` | 28 | 1 (job) ou 9 (policy) |
| `spec/models/event/initiation_spec.rb` | 26 | 1 (job) |
| `spec/requests/admin_panel/initiations_spec.rb` | 11 | 1 (job) |
| `spec/requests/admin_panel/inventory_spec.rb` | 10 | 1 (job) |
| `spec/mailers/event_mailer_spec.rb` | 11 | 1 (job) |
| `spec/requests/registrations_spec.rb` | 16 | 2 (429) + 3 (redirect/jobs) |
| `spec/requests/initiations_spec.rb` | 6 | 1 (job) |
| `spec/models/waitlist_entry_spec.rb` | 8 | 1 (job) |
| `spec/models/attendance_spec.rb` | 3 | 1 (job) |
| `spec/requests/admin_panel/events_spec.rb` | 1 | 1 (job) |
| `spec/requests/admin_panel/dashboard_spec.rb` | 1 | 1 (job) |
| `spec/requests/admin_panel/base_controller_spec.rb` | 1 | 1 (job) |
| `spec/requests/attendances_spec.rb` | 2 | 1 (job) |
| `spec/policies/event/initiation_policy_spec.rb` | 2 | 1 (job) |
| `spec/requests/memberships_spec.rb` | 3 | 6 (memberships) |
| `spec/requests/orders_spec.rb` | 1 | 5 (login_user) |
| `spec/requests/passwords_spec.rb` | 3 | 2 (429) + 8 (current_user) |
| `spec/requests/products_spec.rb` | 1 | 7 (products) |

---

## Prochaines étapes suggérées

1. **Catégorie 1 (job)** : Décider stratégie test (stub global, adapter test avec file d’attente, ou désactiver le callback en test) sans cacher un bug app.
2. **Catégorie 2 (429)** : Vérifier si une safelist Rack::Attack en `test` est acceptable ; sinon adapter les specs (moins de POST ou reset du throttle).
3. **Catégories 3–4** : Valider comportement attendu (welcome vs confirmation, deliver_later, statut refuse = cancelled) puis aligner specs ou app.
4. **Catégories 5–8** : Un spec par type d’erreur, relancer en isolé pour confirmer le message puis corriger test ou app.
5. **Catégorie 9** : Lancer un exemple `admin_panel/event/initiation_policy_spec` seul pour distinguer job vs policy.

---

*Généré pour analyse détaillée – à mettre à jour après chaque correction.*
