# Plan – Tests RSpec & Refactoring

**Dernière mise à jour** : 2026-01-31  
**Référence** : [RSPEC_AUDIT_REPORT.md](RSPEC_AUDIT_REPORT.md)

---

## Vue d'ensemble

| Priorité | Bloc | Statut | Fichier / action |
|----------|------|--------|-------------------|
| 1 | RSpec en CI | ☐ À faire | `.github/workflows/ci.yml` |
| 2 | Specs pending | ☐ À faire | views memberships, roller_stock, memberships_helper |
| 3 | Shared context admin | ☐ À faire | `spec/support/shared_contexts/` |
| 4 | Première méthode refactorée | ☐ À faire | Méthode cible + templates refactoring/ |
| 5 | Couverture zones critiques | ☐ À faire | 1–2 services ou 1 contrôleur admin |
| 6 | (Optionnel) SimpleCov | ☐ À faire | Gemfile + spec_helper / rails_helper |

---

## Priorité 1 : RSpec en CI

**Problème** : La CI exécute `bin/rails test test:system` (Minitest). Les 85 specs RSpec ne sont pas exécutés.

**Actions** :
1. Ouvrir `.github/workflows/ci.yml`.
2. Dans le job `test`, ajouter une étape (ou un job dédié) qui lance RSpec :
   - Exemple : `run: bundle exec rspec` (ou exclure les features si trop lents : `bundle exec rspec --exclude-pattern "spec/features/**/*_spec.rb"`).
3. Vérifier que la base de test est prête avant (`bin/rails db:test:prepare` si besoin).
4. Commit, push, vérifier que le workflow passe.

**Livrable** : RSpec exécuté à chaque push/PR sur les branches configurées.

---

## Priorité 2 : Specs pending

**Fichiers concernés** :
- `spec/views/memberships/create.html.erb_spec.rb`
- `spec/views/memberships/index.html.erb_spec.rb`
- `spec/views/memberships/new.html.erb_spec.rb`
- `spec/views/memberships/pay.html.erb_spec.rb`
- `spec/views/memberships/payment_status.html.erb_spec.rb`
- `spec/views/memberships/show.html.erb_spec.rb`
- `spec/models/roller_stock_spec.rb`
- `spec/helpers/memberships_helper_spec.rb`

**Actions (au choix par fichier)** :
- **Option A** : Remplacer `pending` par 1–2 exemples minimaux (ex. render, contenu attendu).
- **Option B** : Supprimer le spec si la vue/helper n'est pas prioritaire ou si on ne souhaite pas les maintenir.

**Livrable** : Plus de specs en `pending` sans décision (soit exemples, soit suppression).

---

## Priorité 3 : Shared context admin

**Objectif** : Éviter la duplication `let(:admin_user)` + `before { login_user(admin_user) }` dans les request specs admin.

**Actions** :
1. Créer `spec/support/shared_contexts/admin_user.rb` (ou équivalent).
2. Définir un `shared_context "admin user"` qui fournit un utilisateur admin et le login.
3. Inclure ce context dans les request specs admin (ex. `include_context "admin user"` ou metadata).
4. Remplacer progressivement les blocs dupliqués par l'inclusion du context.

**Livrable** : Un seul endroit pour "admin connecté" dans les request specs.

---

## Priorité 4 : Première méthode refactorée (standards 2026)

**Objectif** : Valider le process de refactoring avec une méthode réelle.

**Actions** :
1. Choisir **une** méthode cible (ex. un modèle ou un service critique).
2. Suivre [METHODE.md](METHODE.md) Partie B (Phases 1–6).
3. Créer des copies des templates dans `refactoring/` pour cette méthode (ex. dans un sous-dossier ou avec le nom de la méthode dans le fichier).
4. Remplir : METHODE_CONTEXT → METHODE_RESEARCH → METHODE_ANALYSIS → REFACTORING_PLAN.
5. Appliquer le plan étape par étape (implémentation guidée, validation à chaque étape).
6. Remplir REFACTORING_REPORT en fin de Phase 6.

**Livrable** : Une méthode refactorée + 5 documents de suivi remplis.

---

## Priorité 5 : Couverture zones critiques

**Référence** : Section 3 de [RSPEC_AUDIT_REPORT.md](RSPEC_AUDIT_REPORT.md).

**Actions (au moins une)** :
- **Services** : Ajouter un spec pour au moins un service non couvert (ex. `HelloassoService`, `InventoryService`, `AdminDashboardService`).
- **Request specs** : Ajouter un request spec pour au moins un contrôleur admin sans spec (ex. `homepage_carousels`, `mail_logs`, `maintenance`, `product_variants`, `products`).

**Livrable** : Au moins un nouveau spec sur une zone critique identifiée dans l'audit.

---

## Priorité 6 (optionnel) : SimpleCov

**Actions** :
1. Ajouter `gem "simplecov", require: false` dans le groupe `:test` du Gemfile.
2. En tête de `spec/rails_helper.rb` (ou `spec_helper.rb`), ajouter le chargement et la config SimpleCov (groupe par type, dossier `coverage/`).
3. Lancer `bundle exec rspec`, ouvrir `coverage/index.html` pour voir le taux et les fichiers non couverts.
4. (Optionnel) Ajouter une étape CI qui upload le rapport (artifact ou service externe).

**Livrable** : Rapport de couverture local (et éventuellement en CI).

---

## Ordre recommandé

1. **Priorité 1** (RSpec en CI) → les specs deviennent un garde-fou à chaque push.
2. **Priorité 2** (pending) → suite plus propre.
3. **Priorité 3** (shared context) → moins de duplication, maintenance plus simple.
4. **Priorité 4** (refactoring) → valider la méthode sur une méthode réelle.
5. **Priorité 5** (couverture) → réduire les trous identifiés dans l'audit.
6. **Priorité 6** (SimpleCov) → mesurer l'évolution de la couverture.

---

## Mise à jour de ce plan

- Cocher les cases dans la section « Vue d'ensemble » au fur et à mesure.
- Mettre à jour la date « Dernière mise à jour » en haut du fichier.
- Pour l'avancement détaillé, utiliser le README (point d'entrée) : section « Où on en est ».
