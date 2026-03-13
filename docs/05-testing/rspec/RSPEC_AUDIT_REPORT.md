# Rapport d'audit RSpec – Grenoble Roller

**Date** : 2026-01-31  
**Objectif** : État des lieux factuel pour définir une stratégie de refonte incrémentale des tests.  
**Contraintes** : Analyse factuelle uniquement, pas d'implémentation, pas d'opinions.

---

## Section 1 : État des lieux quantitatif

### 1.1 Arborescence `spec/`

| Dossier        | Fichiers _spec.rb | Autres fichiers | Total |
|----------------|-------------------|------------------|-------|
| models/        | 22                | 0                | 22    |
| models/event/  | 1                 | 0                | 1     |
| requests/      | 14                | 0                | 14    |
| requests/admin_panel/ | 18 | 1 (README)       | 19    |
| policies/      | 1                 | 0                | 1     |
| policies/admin_panel/ | 8  | 0             | 8     |
| policies/admin_panel/event/ | 1 | 0          | 1     |
| features/      | 4                 | 0                | 4     |
| jobs/          | 3                 | 0                | 3     |
| mailers/       | 4                 | 1 (preview)      | 5     |
| helpers/       | 2                 | 0                | 2     |
| views/memberships/ | 6              | 0                | 6     |
| services/     | 1                 | 0                | 1     |
| **Total specs**| **85**            | —                | —     |

**Support** : 8 fichiers dans `spec/support/` (capybara, database_cleaner, devise_controller_helper, product_test_helper, request_authentication_helper, system_authentication_helper, test_data_helper, waitlist_test_helper). Aucun `shared_context` ni `shared_examples` défini dans le projet (uniquement la config RSpec `shared_context_metadata_behavior`).

**Factories** : 22 fichiers dans `spec/factories/` (dont 1 sous-dossier event/initiations.rb). Pas de factory pour : `homepage_carousel`, `event_loop_route`, `maintenance_mode`.

---

### 1.2 Comparaison `spec/` vs `app/`

| Type        | app/ (existant) | spec/ (existant) | Manquants (sans spec dédié) |
|-------------|------------------|-------------------|-----------------------------|
| **Models**  | 27 (hors ApplicationRecord, concerns) | 23 specs (dont event/initiation) | homepage_carousel, event_loop_route, maintenance_mode |
| **Controllers** | ~35 (dont namespaces) | 32 request specs (tous types) | AdminPanel : homepage_carousels, mail_logs, maintenance, product_variants, products (5) ; publics : cookie_consents, health, legal_pages, sessions, confirmations, etc. |
| **Policies**| 27 (admin + admin_panel + event) | 10 policy specs | admin_panel : attendance, contact_message, event, homepage_carousel, maintenance, organizer_application, partner, payment, product_variant, route ; admin/* ; event/initiation (côté event) |
| **Services**| 8 | 1 (RoleAssignmentService) | AdminDashboardService, EmailSecurityService, HelloassoService, InventoryService, OrderExporter, ProductExporter, ProductVariantGenerator (7) |
| **Jobs**    | 6 (hors ApplicationJob) | 3 | SendRenewalRemindersJob, SyncHelloAssoPaymentsJob, UpdateExpiredMembershipsJob (3) |
| **Mailers** | 5 (hors ApplicationMailer, DeviseMailer) | 4 | — (Event, Membership, Order, User couverts) |
| **Helpers** | plusieurs (ApplicationHelper, AdminPanel*, etc.) | 2 (application_helper, memberships_helper) | AdminPanelHelper, AdminPanel::OrdersHelper, etc. |
| **Views**   | nombreuses | 6 (memberships uniquement) | Toutes les autres vues (admin, events, orders, etc.) |

**Couverture estimée (ordre de grandeur)** : models ~85 %, requests admin ~75 %, policies ~40 %, services ~12 %, jobs ~50 %, mailers ~80 %, helpers faible, views très partielle.

---

### 1.3 Outils de couverture

- **SimpleCov** : absent du `Gemfile` (groupes `:test` et `:development, :test`). Aucune référence dans `spec_helper.rb` ni `rails_helper.rb`.
- **Dossier coverage/** : non vérifié (pas de génération de rapport).
- **Conclusion** : pas de mesure de couverture de code actuellement ; état des lieux basé sur comptage de fichiers et présence de specs.

---

## Section 2 : État des lieux qualitatif

### 2.1 Patterns utilisés

- **Models** : `let`, `before`, `describe` / `context`, `expect`. Usage mixte de FactoryBot et de `TestDataHelper` (create_user, ensure_role, build_event, etc.). Parfois création directe (Role.find_or_create_by!, User.create!, etc.).
- **Requests** : `login_user` (RequestAuthenticationHelper), `sign_in` Devise, `context 'when user is admin'` / `'when user is organizer'`, vérifications `have_http_status`, `redirect_to`, `response.body.include?`.
- **Policies** : `describe` sur la policy, exemples sur `permit` / `forbid` selon le rôle.
- **Services** : un seul fichier (RoleAssignmentService) : `let` pour les rôles, `described_class.can_assign_role_to_user?`, pas de shared_examples.
- **Pas de** : `shared_context`, `shared_examples`, `it_behaves_like` dans le code parcouru.

### 2.2 Code dupliqué repéré

- Définition des rôles en `let` ou en inline : `Role.find_or_create_by!(code: 'ADMIN') { ... }` répété dans plusieurs request specs ; parfois factory `create(:user, :admin)`.
- Setup utilisateur + login répété dans chaque `context` (admin, organizer, non connecté).
- Création de commandes/adhésions en `pending` répétée (Order.new(..., status: 'pending'), create(:membership, status: 'pending')).

### 2.3 Incohérences de style

- Mélange **FactoryBot** vs **TestDataHelper** (create_user, ensure_role) selon les fichiers.
- Mélange **login_user** vs **sign_in** dans les request specs.
- Nomenclature : globalement `describe 'GET /path'`, `context 'when user is admin'`, `it 'returns success'` ; quelques descriptions en français, la majorité en anglais.

### 2.4 Specs pending / skip

- **pending** (exemples non implémentés) :  
  `roller_stock_spec.rb` ;  
  `memberships_helper_spec.rb` ;  
  tous les view specs memberships (6 fichiers : create, index, new, pay, payment_status, show).
- **xit** (exemples désactivés) :  
  `features/event_management_spec.rb` (2 exemples : suppression événement avec confirmation, annulation du modal) — motif indiqué : ChromeDriver non disponible.

---

## Section 3 : Zones critiques identifiées

### 3.1 Priorité haute – Non couvertes ou très partielles

1. **Services métier**  
   - HelloassoService, InventoryService, ProductVariantGenerator, OrderExporter, AdminDashboardService, EmailSecurityService, ProductExporter : aucun spec.  
   - Impact : paiements, stock, génération de variantes, exports, dashboard, sécurité email.

2. **Endpoints sensibles sans request spec dédié**  
   - AdminPanel : homepage_carousels, mail_logs, maintenance, product_variants, products.  
   - Côté public : flux paiement (memberships/payments, orders/payments), sessions, confirmations.  
   - Partiellement couverts via d'autres specs (ex. memberships_spec, orders_spec) mais pas de specs ciblés pour certains contrôleurs.

3. **Modèles sans spec**  
   - HomepageCarousel, EventLoopRoute, MaintenanceMode : logique métier et validations non couvertes par des specs dédiés.

4. **Policies non couvertes**  
   - AdminPanel : attendance, contact_message, event, homepage_carousel, maintenance, organizer_application, partner, payment, product_variant, route ; arborescence admin/* et event (hors admin_panel) sans specs policies dédiés dans le même format.

### 3.2 Priorité moyenne – Sous-testées ou à renforcer

1. **Jobs**  
   - SendRenewalRemindersJob, SyncHelloAssoPaymentsJob, UpdateExpiredMembershipsJob : pas de spec.  
   - Jobs déjà couverts : event_reminder, initiation_participants_report, return_roller_stock.

2. **Helpers**  
   - Un seul helper (ApplicationHelper#human_status) bien couvert ; MembershipsHelper en pending ; AdminPanel::OrdersHelper, AdminPanelHelper sans spec.

3. **Views**  
   - Seules les vues memberships ont des fichiers de spec (tous en pending). Aucun spec de vue pour admin, événements, commandes, etc.

### 3.3 Quick wins

- Remplacer les `pending` des view specs memberships par des exemples minimaux (render, contenu attendu) ou les supprimer si hors périmètre.
- Ajouter un shared_context « admin signed in » / « organizer signed in » pour réduire la duplication dans les request specs admin.
- Unifier la création des rôles (FactoryBot traits vs TestDataHelper) dans un seul pattern par type de spec.
- Activer RSpec dans la CI (voir Section 5).

---

## Section 4 : Opportunités de factorisation

### 4.1 Shared contexts à créer

- **`spec/support/shared_contexts/admin_user.rb`** : utilisateur admin (level 60) + `login_user` pour request specs.
- **`spec/support/shared_contexts/superadmin_user.rb`** : idem pour superadmin (level 70).
- **`spec/support/shared_contexts/organizer_user.rb`** : idem pour organizer (level 40).
- Optionnel : **signed_in_user** (utilisateur quelconque connecté) pour réutilisation dans plusieurs request specs.

### 4.2 Shared examples à créer

- **Policies** : « admin can manage resource » / « organizer cannot access » pour les resources admin_panel, afin d'éviter la répétition des mêmes exemples par policy.
- **Requests** : « admin gets 200 » / « non-admin redirects to root with alert » pour les index/show admin, si le pattern reste identique sur plusieurs contrôleurs.

### 4.3 Factories à optimiser

- Rôles : usage déjà partiel de traits (admin, superadmin, organizer). Étendre à tous les request specs pour remplacer les `Role.find_or_create_by!` répétés.
- Éviter les cascades lourdes (ex. user → membership → payment → order) dans les factories ; privilégier des builds minimaux et des associations explicites quand c'est possible.

### 4.4 Support / helpers manquants

- Pas de helper dédié « create_admin_user_and_login » (ou équivalent) réutilisable ; chaque spec refait le `let` + `before { login_user(...) }`.
- Pas de helper pour créer des rôles de test de façon unique (éviter conflits d'unicité entre specs).

---

## Section 5 : Métriques et CI

### 5.1 Pipeline CI actuel

- **Fichier** : `.github/workflows/ci.yml`.
- **Job test** : `bin/rails db:test:prepare test test:system`.
- **Interprétation** : `test` et `test:system` exécutent la suite **Minitest** (dossier `test/`), pas RSpec. Le projet contient à la fois `test/` (Minitest, 13 fichiers dans test/models/) et `spec/` (RSpec, 85 specs). **La suite RSpec n'est pas exécutée en CI.**
- Pas de step dédié à la couverture (SimpleCov ou autre), pas d'upload de rapport de couverture.

### 5.2 Performance (à mesurer en local)

- **Commande suggérée** : `bundle exec rspec --profile 10` pour identifier les 10 exemples les plus lents.
- **Goulots probables** : features (Capybara/système), request specs avec beaucoup de créations (DB), jobs/mailers si chargement de Rails lourd. Non mesuré dans le cadre de cet audit (pas d'exécution lancée).

### 5.3 Ratio approximatif (nombre de fichiers)

- Models : 22 specs  
- Requests : 32 specs (14 publics + 18 admin_panel)  
- Features (system) : 4  
- Policies : 10  
- Jobs : 3  
- Mailers : 4  
- Helpers : 2  
- Views : 6  
- Services : 1  

Ordre de grandeur : ~60 % models + requests, ~15 % policies, reste réparti entre jobs, mailers, helpers, views, features, services.

---

## Synthèse

- **Points forts** : bonne couverture des models principaux, des request specs admin (orders, users, memberships, events, etc.) et des policies de base ; factories présentes pour la plupart des modèles ; support (auth, DB, Capybara) en place.
- **Lacunes principales** : services sans specs, plusieurs contrôleurs admin sans request spec, policies admin_panel partiellement couvertes, pas de SimpleCov, **RSpec non exécuté en CI**.
- **Quick wins** : activer RSpec dans la CI, ajouter un shared_context admin/organizer, traiter les pending (views ou helpers), couvrir 1–2 services critiques (ex. RoleAssignmentService déjà fait, puis HelloassoService ou InventoryService).
- **Refonte lourde** : à prioriser après décision sur le périmètre (tout RSpec vs seulement zones critiques) et sur le choix de garder ou non Minitest en parallèle.

---

*Rapport généré pour servir de base à la stratégie de refonte incrémentale. Aucune implémentation ni modification de code.*
