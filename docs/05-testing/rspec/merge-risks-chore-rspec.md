# Document d’analyse des risques – merge chore/rspec dans Dev

**Objectif :** Avant de merger la branche `chore/rspec` dans `Dev`, ce document recense les conflits, les risques (specs, fonctionnels, dépendances) et une checklist de validation.

**Base commune (merge-base Dev / chore/rspec) :** `4346534c`

---

## 1. Contexte et objectif

- **Objectif :** Récupérer `chore/rspec` dans `Dev` ; ce document liste les conflits, risques et une checklist avant merge.
- **Base commune actuelle :** `4346534c` (merge-base Dev / chore/rspec).

---

## 2. Contenu de chore/rspec (8 commits)

Résumé des apports de la branche :

| Thème | Détail |
|-------|--------|
| **Dépendances** | Brakeman 8, mise à jour de gems et binstubs. |
| **Admin** | Statut des initiations refusées (vues index/show admin + initiations). |
| **Mailer** | Nom du participant dans la confirmation de présence (event_mailer, vues attendance_confirmed). |
| **Attendances / waitlist** | Règles d’inscription, conversion waitlist, contrôleurs initiations (attendances, waitlist_entries), eligibility waitlist. |
| **Seeds** | Gestion d’erreurs et images (db/seeds.rb). |
| **Docs RSpec** | METHODE.md refactorée, nouveaux fichiers PLAN.md, RSPEC_AUDIT_REPORT.md, refactoring/ (METHODE_ANALYSIS, CONTEXT, RESEARCH, REFACTORING_PLAN, REFACTORING_REPORT). |
| **Specs** | attendances_spec, initiations_spec, waitlist_entries_spec retravaillés, event_spec, waitlist_test_helper. |

---

## 3. Conflits de merge (à résoudre manuellement)

Résultat d’un `git merge chore/rspec --no-commit --no-ff` sur Dev (merge ensuite annulé). **10 fichiers en conflit :**

| Fichier | Domaine |
|---------|---------|
| `Gemfile.lock` | Dépendances (versions différentes Dev vs chore/rspec) |
| `app/controllers/initiations/attendances_controller.rb` | Logique initiations / attendances |
| `app/controllers/initiations_controller.rb` | Initiation publique |
| `app/views/admin_panel/initiations/index.html.erb` | Admin initiations |
| `app/views/admin_panel/initiations/show.html.erb` | Admin initiations |
| `app/views/initiations/show.html.erb` | Vue publique initiation |
| `db/seeds.rb` | Données de seed (images, erreurs) |
| `docs/05-testing/rspec/METHODE.md` | Méthodologie (refactor chore/rspec vs version Dev) |
| `docs/05-testing/rspec/README.md` | Index RSpec (ajouts chore/rspec vs Dev) |
| `spec/requests/waitlist_entries_spec.rb` | Specs waitlist |

**Recommandations :**

- **Gemfile.lock** : réconcilier les deux versions (garder les versions de chore/rspec pour Brakeman 8 et les gems mis à jour), puis exécuter `bundle install`.
- **METHODE.md / README.md** : chore/rspec apporte une refonte doc ; choisir la structure voulue (souvent garder la version chore/rspec et réintégrer manuellement les ajouts Dev s’il y en a).
- **Fichiers app/ et spec/** : fusion manuelle selon la logique métier ; privilégier les règles waitlist/attendances de chore/rspec et conserver les évolutions Dev (carousel, bannière, etc.) là où elles ne se recoupent pas.

---

## 4. Risques liés aux specs (post-merge)

Référence : [spec-failures-audit.md](spec-failures-audit.md).

| Catégorie | Impact du merge | Action |
|-----------|-----------------|--------|
| **InitiationParticipantsReportJob** (NotImplementedError `wait_until`) | chore/rspec touche waitlist/attendances/initiations ; les specs listés dans l’audit (event_mailer, attendance, initiation, waitlist_entry, admin_panel, initiation_registration, waitlist_entries) peuvent régresser ou rester en échec. | Exécuter la suite après merge ; traiter tout nouvel échec selon [METHODE.md](METHODE.md). |
| **HTTP 429 (Rack::Attack)** | Pas de changement dans chore/rspec. | Risque inchangé. |
| **Registrations / Passwords** | Pas de changement dans chore/rspec. | Risque inchangé. |
| **Waitlist refuse/decline (pending vs cancelled)** | chore/rspec modifie `spec/requests/waitlist_entries_spec.rb` (fichier en conflit). | Après résolution du conflit, vérifier que les attentes (pending vs cancelled) sont cohérentes avec spec-failures-audit et la logique métier. |
| **Autres** (orders login_user, memberships, etc.) | Pas de modification directe dans chore/rspec. | Lancer la suite complète après merge. |

**Action recommandée :** Après merge et résolution des conflits, lancer `bundle exec rspec spec/` (ou la commande conteneur documentée dans [README.md](README.md)) et traiter tout nouvel échec selon [METHODE.md](METHODE.md).

---

## 5. Risques fonctionnels (app)

| Zone | Risque | Vérification |
|------|--------|----------------|
| **Waitlist / eligibility** | Nouveaux contrôles et règles (waitlist_entries_controller, event, waitlist_entry). | Tester manuellement ou via specs : inscription waitlist, conversion, refus/decline. |
| **Attendances (initiations)** | `initiations/attendances_controller.rb` et logique d’inscription modifiés. | Vérifier inscription / désinscription et cas limite (essai gratuit, enfant, places). |
| **Admin initiations** | Statut « rejeté » (index + show). | Vérifier affichage et filtres. |
| **Seeds** | seeds.rb en conflit. | Après merge, exécuter `db:seed` en dev/staging pour valider (images, erreurs). |

---

## 6. Dépendances

| Élément | Risque | Action |
|---------|--------|--------|
| **Brakeman 8** | Mise à jour majeure ; nouveaux avertissements possibles. | Lancer `bundle exec brakeman` après merge et traiter les éventuelles alertes. |
| **Gemfile.lock** | Conflit à résoudre. | Résoudre le conflit puis `bundle install` ; vérifier qu’aucune gem critique (Rails, RSpec, etc.) n’est rétrogradée ou incompatible. |

---

## 7. Checklist avant de merger

- [ ] Merger `chore/rspec` dans `Dev` et résoudre les 10 conflits.
- [ ] `bundle install` ; pas d’erreur de résolution.
- [ ] `bundle exec rspec spec/` (ou commande conteneur) : 0 échec (ou documenter les régressions).
- [ ] `bundle exec brakeman` : pas de nouvelle alerte bloquante.
- [ ] Vérification manuelle ou specs : waitlist (inscription, conversion, refuse/decline), attendances initiations, admin initiations (statut rejeté), seeds en dev.
- [ ] Mise à jour éventuelle de [spec-failures-audit.md](spec-failures-audit.md) si de nouveaux échecs apparaissent ou sont corrigés.

---

## 8. Références

- [METHODE.md](METHODE.md) — méthodologie de correction des erreurs RSpec.
- [spec-failures-audit.md](spec-failures-audit.md) — échecs connus (InitiationParticipantsReportJob, 429, etc.).
- [README.md](README.md) — index des fiches et commandes.
