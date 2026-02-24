# Erreur #003 : AdminPanel::Event::InitiationPolicy – index? (true) et update? (false)

**Date d'analyse** : 2026-02-24  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Policies – admin panel initiations

---

## 📋 Informations Générales

- **Fichier test** : `spec/policies/admin_panel/event/initiation_policy_spec.rb`
- **Lignes** : 18 (index?), 120 (update?)
- **Tests** : `index? when user is initiation (level 30) is expected to equal true` ; `update? when user is organizer (level 40) is expected to equal false`
- **Commande pour reproduire** :
  ```bash
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/policies/admin_panel/event/initiation_policy_spec.rb:18
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/policies/admin_panel/event/initiation_policy_spec.rb:120
  ```

---

## 🔴 Erreur

- **Ligne 18** : `expected to equal true` (valeur reçue non true pour index? avec user level 30).
- **Ligne 120** : `expected to equal false` (valeur reçue non false pour update? avec user level 40).

Message exact à recopier après relance (possiblement lié à un setup commun : création d’initiation → job, ou scope/record).

---

## 🔍 Analyse

### Constats
- ✅ Les rôles (initiation level 30, organizer level 40) sont cohérents avec le reste de l’app.
- ❌ La policy retourne une valeur différente de ce que le spec attend pour ces rôles.
- 🔍 Vérifier si le setup du spec crée une initiation (callback job) ou modifie le `record`/`scope` de façon inattendue.

### Cause Probable
- Règles de la policy (AdminPanel::Event::InitiationPolicy) pour `index?` et `update?` ne correspondent pas aux attentes du spec (niveau requis, rôle organizer vs initiation).
- Ou le `record`/contexte passé à la policy dans le spec n’est pas celui attendu.

### Code Actuel
À compléter : `app/policies/admin_panel/event/initiation_policy.rb` (méthodes `index?`, `update?`), et le setup du spec (user, role, record).

---

## 📚 Référence doc projet (initiations & rôles)

**Principe** : **Seuls les numéros (level) sont la vérité** pour les permissions. Les noms des grades (codes, libellés) sont modifiables et ne doivent pas servir de référence en logique — on raisonne toujours en **level 30**, **level 40**, **level 60**, etc.

### Doc policies initiations
- **`docs/04-rails/admin-panel/03-initiations/06-policies.md`** (doc de référence pour InitiationPolicy) :
  - **Lecture** (`index?`, `show?`) : **level >= 30** → INITIATION (30), ORGANIZER (40), MODERATOR (50), ADMIN (60), SUPERADMIN (70).
  - **Écriture** (`create?`, `update?`, `destroy?`) : **level >= 60** → `admin_user?` (ADMIN, SUPERADMIN).
  - `return_material?` : level >= 40.

### Doc permissions globales
- **`docs/04-rails/admin-panel/PERMISSIONS.md`** :
  - Tableau des grades : indique ORGANIZER = 30, INITIATION = 40 → **inversé par rapport aux seeds** ; à considérer comme erroné pour les numéros de level.
  - Règle métier décrite : grade 40+ = lecture initiations, grade 60+ = écriture ; grade 30 = aucun accès. Si on lit “grade 30” comme le rôle qui a level 30, alors avec les seeds (INITIATION = 30) cela signifierait “INITIATION n’a pas accès”, ce qui contredit 06-policies.md (index? >= 30).

### Code actuel
- **Policy** (`app/policies/admin_panel/event/initiation_policy.rb`) :
  - `can_view_initiations?` = **level >= 40** (donc index?/show? refusés au level 30).
  - `create?` / `update?` / `destroy?` = **can_view_initiations?** (level >= 40) → organizer (40) a le droit de modifier, alors que la doc 06-policies exige `admin_user?` (>= 60).
- **BaseController** (`app/controllers/admin_panel/base_controller.rb`) :
  - Accès initiations si **level >= 40** → un user INITIATION (30) est redirigé avant même d’atteindre la policy.
  - Commentaire “Level 30 = ORGANIZER, Level 40 = INITIATION” → inversé par rapport aux seeds.

**Conclusion doc** : La référence à suivre pour les initiations est **06-policies.md** + **seeds** : lecture à partir de **30**, écriture à partir de **60**. La policy et le BaseController actuels sont alignés sur un seuil 40 et donnent l’écriture à 40+, ce qui ne correspond pas à cette doc.

---

## 💡 Solutions Proposées (logique détaillée A vs B)

### Option A : Aligner la policy (et le contrôleur) sur le spec et la doc 06-policies

**Règle métier cible** (doc 06-policies, par level uniquement) :
- **Lecture** (index?, show?) : **level >= 30**
- **Écriture** (create?, update?, destroy?) : **level >= 60** (level 40 et 50 ne peuvent pas)

**Modifications à faire** :
1. **Policy**  
   - `can_view_initiations?` : passer le seuil de **40 à 30**.  
   - `create?`, `update?`, `destroy?` : utiliser **`admin_user?`** (level >= 60) au lieu de `can_view_initiations?`.
2. **BaseController**  
   - Pour le contrôleur `initiations` (et évent. homepage_carousels / homepage_announcements) : autoriser l’accès à partir de **level >= 30** au lieu de 40, pour que les users avec level 30 atteignent la policy.
3. **Commentaires**  
   - Utiliser uniquement les numéros de level dans les commentaires (pas les noms de grades).

**Effet** : Les specs pour index? et update? passent. **Attention** : la doc 06-policies exige `destroy?` = `admin_user?` (60+). Le spec actuel attend `destroy?` true pour organizer (40) et moderator (50) ; en appliquant A, il faudra aligner le spec sur la doc : `destroy?` false pour 40 et 50, true pour 60+ (sinon les exemples destroy? pour organizer/moderator échoueront).

---

### Option B : Aligner le spec sur la policy actuelle (garder level >= 40, écriture à 40+)

**Règle métier cible** (comportement actuel du code) :
- **Lecture** : **level >= 40** (level 30 refusé)
- **Écriture** : **level >= 40**

**Modifications à faire** :
1. **Spec**  
   - `index?` pour user “initiation (level 30)” : attendre **false** au lieu de true (et adapter le libellé du contexte).  
   - `update?` pour user “organizer (level 40)” : attendre **true** au lieu de false.
2. **Doc**  
   - Mettre à jour **06-policies.md** (et éventuellement PERMISSIONS.md) pour décrire ce comportement (lecture et écriture à partir de 40), sinon la doc et le code restent en contradiction.

**Effet** : Level 30 n’a plus accès ; l’écriture est élargie à level >= 40. À documenter en conséquence (06-policies) si on garde ce choix.

---

## 🎯 Recommandation

- **Recommandation** : **Option A** — aligner le code sur **06-policies.md** (par level) : lecture >= 30, écriture >= 60.  
- **Option B** : garder le code actuel (lecture/écriture >= 40) et mettre à jour le spec + la doc.

---

## 🎯 Type de Problème

**PROBLÈME DE LOGIQUE** : la policy (et le BaseController) ne respectent pas la doc 06-policies (levels) ; le spec reflète la règle par level décrite dans la doc.

---

## 📊 Statut

✅ **RÉSOLU** (Option A appliquée) – Policy et BaseController alignés sur 06-policies (lecture >= 30, écriture >= 60). Spec mis à jour (create?/destroy? false pour level 40 et 50). 31 examples, 0 failures.

---

## 🔗 Erreurs Similaires

- [004-admin-initiations-redirect.md](004-admin-initiations-redirect.md) (initiations_spec 54, 137, 170 ; base_controller 18).

---

## 📝 Notes

- Voir [spec-failures-audit.md](../spec-failures-audit.md) liste #5, #6, #7.

---

## ✅ Actions à Effectuer

1. [x] Relancer les specs :18 et :120 et coller le message d’erreur complet.
2. [x] Lire `app/policies/admin_panel/event/initiation_policy.rb` pour index? et update?.
3. [x] Décider : corriger la policy ou les attentes du spec, puis appliquer.
4. [x] Mettre à jour le statut dans [README.md](../README.md).

### Modifications appliquées
- **InitiationPolicy** : `can_view_initiations?` → level >= 30 ; `create?`/`update?`/`destroy?` → `admin_user?` (>= 60) ; `return_material?` → `can_return_material?` (>= 40).
- **BaseController** : accès initiations / homepage_carousels / homepage_announcements si level >= 30 (au lieu de 40).
- **Spec** : `create?` et `destroy?` attendus à false pour level 40 et 50.
- **Seeds** : déjà conformes à la prod (USER 10 … SUPERADMIN 70), aucune modification.
