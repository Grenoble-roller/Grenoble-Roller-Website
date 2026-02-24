# Méthodologie de Travail - Correction des Erreurs RSpec

**Date de création** : 2025-01-13

---

## 🎯 Objectif

Corriger systématiquement toutes les erreurs RSpec en suivant une méthodologie claire et reproductible.

---

## 📋 Processus de Travail

### Étape 1 : Analyser l'erreur

1. **Exécuter le test spécifique** pour voir l'erreur exacte (avec `RAILS_ENV=test` si tu passes par le conteneur dev) :
   ```bash
   docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/[chemin]/[fichier]_spec.rb:XX
   ```
   Ou avec le nom du conteneur : `docker exec -e RAILS_ENV=test grenoble-roller-dev bundle exec rspec ./spec/...`

2. **Copier l'erreur complète** dans le fichier d'erreur

3. **Lire le code du test** pour comprendre ce qu'il teste

4. **Lire le code de l'application** (modèle, contrôleur, etc.) pour comprendre la logique

### Étape 2 : Documenter l'erreur

1. **Créer ou mettre à jour le fichier d'erreur** dans `docs/05-testing/rspec/errors/`
2. **Remplir toutes les sections** :
   - Informations générales
   - Erreur complète
   - Analyse détaillée
   - Solutions proposées
   - Type de problème
   - Statut

### Étape 3 : Identifier le type de problème

**❌ PROBLÈME DE TEST** :
- Configuration manquante ou mal placée
- Données de test incorrectes
- Helpers ou mocks manquants
- Nettoyage de données insuffisant

**⚠️ PROBLÈME DE LOGIQUE** :
- Bug dans le code de l'application
- Logique métier incorrecte
- Validations ou associations manquantes
- Templates ou helpers incorrects

### Étape 4 : Proposer des solutions

1. **Identifier plusieurs solutions possibles**
2. **Tester la solution la plus simple d'abord**
3. **Documenter chaque solution** avec du code

### Étape 5 : Appliquer la correction

1. **Appliquer la solution** dans le code
2. **Exécuter le test** pour vérifier qu'il passe
3. **Vérifier qu'on n'a pas cassé d'autres tests** :
   ```bash
   docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/[chemin]/[fichier]_spec.rb
   ```
4. **Vérifier l'impact des modifications** :
   - Identifier les **vues / écrans** concernés par le code modifié (contrôleur, modèle, service).
   - Si des vues ou flux utilisateur sont touchés : **test manuel** des écrans concernés (ou au minimum relire le code pour confirmer l’absence de régression).
   - Documenter dans la fiche d’erreur si un impact vue a été vérifié (ou « aucune vue modifiée »).

### Étape 6 : Mettre à jour la documentation

1. **Mettre à jour le statut** dans le fichier d'erreur
2. **Mettre à jour le statut** dans `README.md`
3. **Ajouter des notes** si nécessaire

---

## 🔄 Ordre de Priorité

1. **Priorité 1** : Tests de Contrôleurs Devise (8 erreurs)
2. **Priorité 2** : Tests de Request Devise (5 erreurs)
3. **Priorité 3** : Tests de Sessions (2 erreurs)
4. **Priorité 4** : Tests Feature Capybara (19 erreurs)
5. **Priorité 5** : Tests de Jobs (3 erreurs)
6. **Priorité 6** : Tests de Mailers (30+ erreurs)
7. **Priorité 7** : Tests de Modèles (100+ erreurs)
8. **Priorité 8** : Tests de Policies (1 erreur)
9. **Priorité 9** : Tests de Request (20+ erreurs)

---

## 📝 Checklist pour Chaque Erreur

- [ ] Erreur exécutée et copiée
- [ ] Code du test lu et compris
- [ ] Code de l'application lu et compris
- [ ] Type de problème identifié (test ou logique)
- [ ] Solutions proposées documentées
- [ ] Solution appliquée
- [ ] Test passé
- [ ] Vérification impact : autres tests + vues/écrans concernés (test manuel ou relecture)
- [ ] Documentation mise à jour
- [ ] Statut mis à jour dans README.md

---

## 🎯 Règles d'Or

1. **Une erreur à la fois** : Ne pas mélanger plusieurs corrections
2. **Toujours tester** : Vérifier que la correction fonctionne
3. **Documenter tout** : Mettre à jour les fichiers d'erreur
4. **Vérifier les dépendances** : S'assurer qu'on ne casse pas d'autres tests ; vérifier l'impact sur les vues/écrans concernés (étape 5.4)
5. **Suivre les priorités** : Traiter les erreurs par ordre de priorité

---

## 🔗 Liens Utiles

- [README.md](README.md) - Checklist générale
- [Template d'erreur](errors/TEMPLATE.md) - Template pour créer de nouveaux fichiers d'erreur
- [Stratégie de tests](../strategy.md) - Documentation générale sur les tests

