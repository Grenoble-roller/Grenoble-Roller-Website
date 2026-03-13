# Plan de refactoring – Phase 4

**Méthode** : `[fichier] #[nom_méthode]`  
**Date** : YYYY-MM-DD

---

## Stratégie

- [ ] **Option A** : In-place (< 30 %)
- [ ] **Option B** : Extraction service (30–70 %)
- [ ] **Option C** : Refonte architecture (> 70 %)

**Justification** :

---

## Objectifs

- **Principal** :
- **Secondaires** :

---

## Étapes

### 1. Sécuriser avec tests
- [ ] Vérifier couverture existante
- [ ] Ajouter tests caractérisation si < 80 %
- [ ] Suite verte

### 2. Extractions simples
- [ ] Variables intermédiaires / constantes
- [ ] Sous-méthodes privées
- [ ] Tests verts

### 3. Optimisations queries (si applicable)
- [ ] includes / preload / eager_load
- [ ] find_each si grosse collection
- [ ] select pour limiter colonnes
- [ ] Tests verts

### 4. Simplifications logiques
- [ ] Guard clauses / early return
- [ ] Remplacer rescue nil par &. ou rescue ciblé
- [ ] Simplifier conditionnels (case / hash)
- [ ] Tests verts

### 5. Extraction service (si B/C)
- [ ] Créer `app/services/...`
- [ ] Implémenter #call ou #perform
- [ ] Créer spec service
- [ ] Migrer appel
- [ ] Tests verts

### 6. Cleanup
- [ ] Code mort
- [ ] Renommage
- [ ] YARD si besoin
- [ ] Rubocop OK

### 7. Documentation
- [ ] CHANGELOG.md
- [ ] Breaking changes si API publique

---

## Risques

| Risque | Mitigation |
|--------|------------|
| | |

---

## Rollback

Si échec : revenir au commit stable, analyser, découper en étapes plus petites.
