# Sprint SAO – Améliorations SEO & GEO (Cycle Shape Up)

**Pitch ID**: SEO‑2026‑09  
**Nom du sprint** : Améliorations SEO & GEO  
**Appetite** : 2 semaines de développement (Building) + 1 semaine de Cooldown  
**Date de début** : 2026-09-20  
**Date de fin (Building)** : 2026-10-04  
**Cooldown** : 2026-10-05 au 2026-10-11  

## 1. SHAPING (Semaine -2 à 0)

### Problème utilisateur
Les utilisateurs ont du mal à trouver le site via les moteurs de recherche et les partages sociaux, ce qui limite la visibilité des événements, de la boutique et des adhésions. L’audit Ahrefs montre un score SEO de 12/100 et plusieurs points faibles (données structurées manquantes, titre trop court, méta description trop longue, absence de canonique, ancres génériques, balises OG/Twitter manquantes, vitesse de chargement).

### Appetite (fixe)
2 semaines de travail effectif (10 jours ouvrables). Si le travail n’est pas terminé, on réduit le scope, on n’étend pas la deadline.

### Scope
**In** :
- Ajout de données structurées JSON‑LD (type `Organization` sur toutes les pages, type `Event` sur les pages d’événement).
- Titre de page allongé à 40‑60 caractères.
- Méta description raccourcie à ≤ 160 caractères.
- Balise canonique `<link rel="canonical">` sur chaque page.
- Remplacement des ancres génériques (« cliquez ici ») par des ancres descriptives.
- Ajout des balises Open Graph (`og:title`, `og:description`, `og:image`) et Twitter Card (`twitter:card`).
- Implémentation d’une FAQ minimale avec formulations Q&R (Comment/Quoi/Pourquoi) pour gagner des points GEO.
- Optimisations de performance de base : activation de la compression Brotli côté serveur (si disponible), minification des assets déjà présente, ajout du lazy‑loading sur les images hors viewport via un helper.

**Out** :
- Refonte complète de l’architecture d’URL.
- Migration vers un nouveau système de gestion des métadonnées (ex. gem spécialisée).
- Travaux lourds d’optimisation du critical rendering path (inlining CSS, serveur HTTP/2, CDN).
- Création d’un blog ou d’une section de contenu éditorial importante.

### Rabbit holes (à éviter)
- Passer trop de temps à choisir le schéma JSON‑LD parfait (commencer avec `Organization` et ajouter `Event` uniquement si le temps le permet).
- Essayer d’imposer une stratégie de mots‑clés complète (keyword research) – cela dépasse l’appetite.
- Optimiser le temps de serveur au-delà de l’activation de la compression (c’est du technical debt pour le cooldown).
- Réécrire tous les partials de mise en page pour intégrer les métas – on utilisera un helper et un layout existant.

### Pitch (à présenter à la betting table)
> **Le site du Grenoble Roller souffre d’une mauvaise visibilité sur les moteurs de recherche et les réseaux sociaux, ce qui limite la découverte des événements, de la boutique et des adhésions. En deux semaines, nous allons implémenter les correctifs SEO de base (données structurées, titres, méta, canonique, ancres descriptives, balises OG/Twitter) et quelques améliorations de performance légères afin de remonter le score Ahrefs de 12/100 à au moins 50/100, améliorer le taux de clic dans les SERP et les partages sociaux, et préparer le terrain pour des travaux d’optimisation plus poussés durant le cooldown ou les cycles suivants.**

**Output** : Pitch validé pour la betting table.

## 2. BETTING TABLE (Semaine 0)

- Présenter le pitch (15 min) à l’équipe produit/tech.
- Vote / engagement : si accepté, le projet passe en phase Building.
- **Output** : Projet validé pour le cycle.

## 3. BUILDING (Semaines 1‑3)

### Semaine 1‑2 : Get One Piece Done
Chaque jour, l’équipe choisit la plus petite unité de valeur livrable et la termine avant de passer à la suivante. Exemple de séquence :

| Jour | Task | Done Criteria |
|------|------|---------------|
| J1 | Créer helper SEO (`application_helper.rb`) avec méthodes pour titre, méta, canonique, OG, Twitter, JSON‑LD Organization/Event. | Helper créé et testé sur une page de test. |
| J2 | Intégrer le helper dans le layout (`application.html.erb`) : insérer `<%= seo_title %>`, `<%= seo_description %>`, `<%= seo_canonical %>`, `<%= seo_og_tags %>`, `<%= seo_twitter_card %>`, `<%= seo_json_ld %>`. | Toutes les pages affichent les nouvelles métas (vérifier via view source). |
| J3 | Implémenter les données structurées JSON‑LD `Organization` sur toutes les pages via le helper. | Script JSON‑LD présent et valide (test avec Google Rich Results Test). |
| J4 | Ajouter les données structurées `Event` sur les pages d’événement (`events#show`, éventuellement `events#index`). | Rich Results Test valide pour au moins un événement. |
| J5 | Raccourcir la méta description à ≤ 160 caractères sur toutes les pages (via helper). | Longueur vérifiée avec outil SEO. |
| J6 | Allonger le titre de page entre 40‑60 caractères (via helper). | Titre vérifié. |
| J7 | Ajouter la balise canonique via le helper. | Balise présente sur chaque page. |
| J8 | Ajouter les balises Open Graph (`og:title`, `og:description`, `og:image`) et Twitter Card (`twitter:card`) via le helper. | Balises présentes et contenant des valeurs non vides. |
| J9 | Remplacer les ancres génériques (« cliquez ici ») par des ancres descriptives dans les vues identifiées (ex. `pages/home.html.erb`, `events/index.html.erb`, `shop/index.html.erb`). | Aucune ancre générique restante (recherche regex). |
| J10 | Corriger la hiérarchie des titres :<br>• Supprimer ou convertir le H1 qui n’est pas du contenu réel (ex. « La communauté Roller Grenobloise » en `<div class="visually-hidden">` ou le supprimer).<br>• Assurer un ordre consécutif H1→H2→H3→H4… sans sauter de niveaux (convertir H5 inapproprié en H3 ou ajouter H3 manquant).<br>• Vérifier les vues : `pages/home.html.erb`, `events/index.html.erb`, `static/about.html.erb`, etc. | Aucune hiérarchie de titre sautée ; un seul H1 pertinent par page ; pas de H5 utilisé comme simple libellé d’interface. |
| J11 | Implémenter une mini‑FAQ (3‑4 questions) avec formulations Q&R (Comment/Quoi/Pourquoi) sur la page d’accueil ou une page dédiée. | FAQ présente et utilise des mots comme Comment, Quoi, Pourquoi. |
| J12 | Ajouter `og:image` avec une image représentative (logo ou photo d’événement) via le helper ; permettre de surcharger par `content_for :og_image` sur les pages d’événement. | Balise og:image présente avec URL valide. |
| J13 | Activation de la compression Brotli/Gzip côté serveur (vérifier config Nginx/Apache ou ajouter dans `config/environments/production.rb`). | Réponse HTTP contient `Content-Encoding: br` ou `gzip`. |
| J14 | Ajout du lazy‑loading sur les images hors viewport (ajouter `loading="lazy"` via helper d’image ou directement dans les vues où pertinent). | Images possèdent l’attribut `loading="lazy". |
| J15‑J16 | Buffer / révision : corriger les éventuels bugs, vérifier que aucune régression n’est apparue (ex. titre dupliqué, méta vide, mauvaise hiérarchie). | Tous les tests manuels passés, aucune erreur en console. |

### Semaine 3 : Map Scopes
- Revue de l’ensemble des livrables par rapport au scope initial.
- Identification des tâches « Done » et des éventuels travaux restants.
- Décision de ce qui peut être considéré comme « shippable » (ex. toutes les métas et données structurées sont en place, le reste peut être déplacé au cooldown).
- Mise à jour du tableau de suivi (Treasure ou Jira) avec les tâches terminées et celles reportées.

### Jour 15 : Downhill Execution
- Dernier jour de la phase Building : travailler sur les tâches restantes les plus simples, préparer le déploiement en staging.
- Effectuer un « smoke test » sur staging.grenoble-roller.org : vérifier les métas via View Source, exécuter l’audit Ahrefs rapide (ou Lighthouse) pour confirmer l’amélioration du score.
- Préparer le tag de version et la note de release.

**Output** : Feature shippable – toutes les améliorations SEO de base sont en production/staging, prête pour le betting table du prochain cycle.

## 4. COOLDOWN (Semaine 4)

- **Bug fixes prioritaires** : traiter les éventuels bugs découverts durant le downhill (ex. titre manquant sur certaines pages, données structurées invalides).
- **Technical debt paydown** : 
  - Nettoyer le helper SEO si il devient trop lourd (séparer en partials).
  - Mettre en place des tests automatisés (RSpec) pour vérifier la présence des métas essentielles.
- **Exploration technique** : 
  - Étudier l’implémentation d’un système de gestion des métadonnées plus robuste (ex. gem `meta-tags`).
  - Préparer une stratégie de mots‑clés et de contenu pour les prochains cycles (blog, guides).
- **Documentation** : 
  - Mettre à jour `docs/09-product/seo-audit.md` avec les actions effectuées et les résultats (score Ahrefs après améliorations).
  - Ajouter un guide `docs/09-product/seo-best-practices.md` pour l’équipe.
- **Innovation** : 
  - Brainstorming d’une idée de feature pour le prochain cycle (ex. intégration d’un calendrier d’événements enrichi, programme de fidélité).

**Output** : Projet stabilisé, dette technique réduite, documentation à jour, équipe prête pour le prochain cycle de shaping.

## 5. Livrables à vérifier à la fin du Building

- [ ] Helper SEO créé et utilisé dans le layout.
- [ ] Données structurées JSON‑LD `Organization` présentes sur toutes les pages.
- [ ] Données structurées `Event` présentes sur les pages d’événement.
- [ ] Titre de page entre 40‑60 caractères.
- [ ] Méta description ≤ 160 caractères.
- [ ] Balise canonique présente.
- [ ] Ancres génériques remplacées.
- [ ] Balises OG (`og:title`, `og:description`, `og:image`) présentes.
- [ ] Balise Twitter Card présente.
- [ ] FAQ avec formulations Q&R ajoutée.
- [ ] Compression Brotli/Gzip activée.
- [ ] Images avec `loading="lazy"` où approprié.
- [ ] Aucun erreur JavaScript liée au nouveau helper (console clean).
- [ ] Score Ahrefs amélioré (cible ≥ 30/100, idéal ≥ 50/100).
- [ ] Déploiement réussi sur staging.grenoble-roller.org.

## 6. Rétrospective (à faire pendant le cooldown)

- Ce qui a bien fonctionné : découpage en tâches très petites, utilisation d’un helper centralisé.
- Ce qui peut être amélioré : prévoir plus de temps pour la rédaction de contenu SEO (FAQ) si l’on veut plus de profondeur.
- Décisions pour le prochain cycle : éventuellement ajouter un système de gestion des métadonnées via gem, travailler sur la stratégie de mots‑clés, améliorer davantage le temps de chargement (critical CSS, CDN).

---  
*Ce fichier doit être conservé dans `docs/02-shape-up/sprint-plan-seo-improvements.md` pour référence future et suivi du cycle.*