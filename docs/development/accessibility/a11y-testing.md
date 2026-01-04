---
title: "Guide Tests Accessibilité Automatisés"
status: "active"
version: "2.0"
created: "2025-11-14"
updated: "2025-01-30"
tags: ["accessibility", "a11y", "testing", "automation"]
---

# Guide Tests Accessibilité Automatisés

## 📋 Prérequis

1. **Application Rails en cours d'exécution**
   ```bash
   # En local
   bin/dev
   # Ou en Docker
   docker compose -f ops/dev/docker-compose.yml up
   ```

2. **Node.js et npm installés**
   ```bash
   node --version
   npm --version
   ```

3. **Dépendances installées**
   ```bash
   npm install
   ```

## 🚀 Utilisation

### Test complet (Pa11y + Lighthouse)
```bash
npm run test:a11y
```

### Tests individuels

#### Pa11y uniquement
```bash
npm run test:a11y:pa11y
```

#### Lighthouse uniquement
```bash
npm run test:a11y:lighthouse
```

## 📊 Résultats

Les rapports sont sauvegardés dans :
```
docs/08-security-privacy/a11y-reports/
```

- **Pa11y** : `pa11y-YYYYMMDD_HHMMSS.txt`
- **Lighthouse** : `lighthouse-{page}-{timestamp}.json`

## ⚙️ Configuration

### URLs testées

Par défaut, les tests vérifient :
- `http://localhost:3000` (Homepage)
- `http://localhost:3000/association`
- `http://localhost:3000/shop`
- `http://localhost:3000/events`
- `http://localhost:3000/users/sign_in`
- `http://localhost:3000/users/sign_up`

### Changer l'URL de base
```bash
BASE_URL=http://localhost:3001 npm run test:a11y
```

### Configuration Pa11y

Fichier : `.pa11yci.json`
- Standard : WCAG2AA
- Timeout : 10s
- Wait : 1s

## 🔍 Interprétation des résultats

### Lighthouse
- **Score ≥ 90** : ✅ Excellent
- **Score 80-89** : ⚠️ Bon, améliorations possibles
- **Score < 80** : ❌ À améliorer

### Pa11y
- **0 erreurs** : ✅ Conforme
- **Erreurs** : Voir détails dans le rapport

## ✅ Tests Recommandés pour Vérifier la Conformité

### 1. Tests Automatisés (À exécuter maintenant)

#### Pa11y - Vérification WCAG 2.1 AA
```bash
npm run test:a11y:pa11y
```
**Objectif** : Vérifier que les 6 pages principales sont toujours conformes après les modifications récentes (filtres, pagination).

**Pages à tester** :
- ✅ Homepage
- ✅ Association
- ✅ Boutique
- ✅ Événements (avec filtres)
- ✅ Connexion
- ✅ Inscription

**Résultat attendu** : 0 erreur sur toutes les pages

#### Lighthouse - Score Accessibilité
```bash
npm run test:a11y:lighthouse
```
**Objectif** : Vérifier le score d'accessibilité (cible : ≥90/100).

**Pages à tester** : Les mêmes 6 pages

**Résultat attendu** : Score ≥90/100 pour chaque page

### 2. Tests Manuels Complémentaires (Optionnels mais recommandés)

#### Navigation Clavier
- ✅ **Déjà validé** en novembre 2025
- **À refaire si** : Modifications importantes de la navigation

#### Test Lecteur d'écran (NVDA)
- ⏳ **À faire** : Tester les parcours principaux avec NVDA
- **Parcours à tester** :
  - Inscription → Confirmation email
  - Navigation événements avec filtres
  - Inscription à un événement
  - "Mes sorties" avec filtres et pagination

#### Vérification Contrastes
- ⏳ **À faire** : Validation finale avec WebAIM Contrast Checker
- **Éléments à vérifier** :
  - Badges et boutons
  - Textes sur images
  - Liens dans footer

#### Test Responsive Mobile
- ⏳ **À faire** : Vérifier avec zoom 200% et tailles tactiles
- **Points à vérifier** :
  - Tous les éléments interactifs ≥44×44px
  - Navigation clavier fonctionnelle
  - Contenu lisible sans scroll horizontal

### 3. Audit Admin (Optionnel)

**ActiveAdmin** - À auditer si nécessaire :
- Tableaux : Headers associés aux cellules
- Formulaires : Labels et erreurs ARIA
- Navigation : Clavier dans sidebar

## 📝 Notes

- Les tests nécessitent que l'application soit accessible
- Lighthouse nécessite Chrome/Chromium
- Les rapports JSON Lighthouse peuvent être visualisés sur https://googlechrome.github.io/lighthouse/viewer/
- **Derniers tests** : Novembre 2025 (6/6 pages conformes Pa11y)
- **À relancer** : Après modifications récentes (filtres, pagination)

## 🎯 Plan d'Action Recommandé

1. **Maintenant** : Exécuter `npm run test:a11y` pour vérifier la conformité actuelle
2. **Si erreurs** : Corriger et relancer les tests
3. **Optionnel** : Tests manuels complémentaires (lecteur d'écran, contrastes)
