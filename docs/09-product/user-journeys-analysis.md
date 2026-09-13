---
title: "User Journeys Analysis"
status: "active"
version: "1.0"
created: "2025-11-14"
updated: "2026-08-14"
authors: ["FlowTech"]
tags: ["product", "ux", "user-journeys", "analysis", "shape-up"]
---

# User Journeys Analysis

**Document Type** : User journey analysis and improvement opportunities identification  
**Methodology** : Shape Up - Building Phase (Cooldown)

---

## 📋 Objectif

Identifier tous les parcours utilisateur de l'application, détecter les points de friction, et documenter les améliorations possibles pour améliorer l'expérience utilisateur.

---

## 👥 Personas Identifiés

### 1. **Membre Actif** (Utilisateur principal)
- **Profil** : Membre de l'association, participe régulièrement aux événements
- **Besoins** : Découvrir les événements, s'inscrire facilement, gérer ses inscriptions
- **Fréquence** : 2-3 fois par semaine
- **Niveau technique** : Intermédiaire (utilise smartphone, réseaux sociaux)

### 2. **Organisateur** (Créateur d'événements)
- **Profil** : Membre avec rôle ORGANIZER, crée et gère des événements
- **Besoins** : Créer des événements facilement, voir les inscriptions, gérer les participants
- **Fréquence** : 1-2 fois par mois
- **Niveau technique** : Intermédiaire à avancé

### 3. **Administrateur** (Gestion back-office)
- **Profil** : Membre avec rôle ADMIN/SUPERADMIN, gère l'application
- **Besoins** : Modérer les événements, gérer les utilisateurs, voir les statistiques
- **Fréquence** : Quotidienne
- **Niveau technique** : Avancé

### 4. **Visiteur Non Connecté** (Découverte)
- **Profil** : Personne découvrant l'association, pas encore membre
- **Besoins** : Découvrir l'association, voir les événements, comprendre comment s'inscrire
- **Fréquence** : Ponctuelle
- **Niveau technique** : Variable

---

## 🗺️ Parcours Utilisateur Identifiés

### 📍 **Parcours 1 : Découverte de l'Association (Visiteur)**

**Objectif** : Découvrir l'association et comprendre ce qu'elle propose

**Étapes** :
1. Arrivée sur la homepage
2. Navigation vers "Association" (présentation, valeurs, bureau)
3. Consultation des événements à venir
4. Décision : s'inscrire ou revenir plus tard
**Récit du parcours actuel** :
L'utilisateur arrive sur la homepage avec un hero banner attractif ("La communauté Roller Grenobloise !") et un message clair sur l'objectif (événements, partages, connexions). Le prochain événement est mis en avant avec une card détaillée (date, lieu, places restantes, actions). La navigation principale est claire (Accueil, L'association, Événements, Boutique) avec des icônes Bootstrap. Pour un visiteur non connecté, deux CTA sont visibles : "Découvrir les événements" et "Connexion/S'inscrire". Si aucun événement n'est programmé, un message rassurant s'affiche avec un lien vers tous les événements.

**Points de friction potentiels** :
- [ ] Homepage claire sur les valeurs et l'objectif de l'association ?
- [ ] Navigation intuitive vers les sections importantes ?
- [ ] Call-to-action clair pour s'inscrire ?
- [ ] Informations sur les tarifs d'adhésion facilement accessibles ?
**Points forts actuels** :
- ✅ Hero banner impactant avec message clair
- ✅ Prochain événement mis en avant (si disponible)
- ✅ Navigation claire avec icônes
- ✅ CTA visibles pour visiteur non connecté
- ✅ Gestion gracieuse de l'absence d'événements

**Points de friction identifiés** :
- [ ] **Manque de contexte sur l'association** : Le hero parle de "communauté" mais ne mentionne pas explicitement les valeurs (Convivialité, Sécurité, Dynamisme, Respect) ni l'historique (15+ ans)
- [ ] **Pas de section "À propos" visible** : L'utilisateur doit cliquer sur "L'association" pour découvrir l'asso, mais ce n'est pas évident
- [ ] **Tarifs d'adhésion non visibles** : Le bouton "Adhérer" dans le hero redirige vers `#adhesion` (ancre) mais cette section n'est pas visible sur la homepage
- [ ] **Pas de témoignages/social proof** : Aucun élément rassurant (nombre de membres, événements passés, photos)
- [ ] **CTA "Adhérer" ambigu** : Pour un visiteur non connecté, le bouton "Adhérer" apparaît mais nécessite d'être connecté d'abord
- [ ] **⚠️ CRITIQUE : Footer avec liens morts** : Le footer complet contient de nombreux liens vers `#` (non fonctionnels) : Qui sommes-nous, Équipe, Carrières, Blog, Catégories, Villes, FAQ, Contact, CGU, Confidentialité, réseaux sociaux, newsletter. Cela crée une frustration majeure pour les utilisateurs qui cliquent sur ces liens.

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **⚠️ URGENT : Corriger les liens morts du footer** : Remplacer les liens `#` par des routes fonctionnelles ou masquer temporairement les sections non implémentées
- [ ] **Ajouter une section "À propos" sur la homepage** : 2-3 lignes avec valeurs + lien "En savoir plus" vers page Association
- [ ] **Rendre le bouton "Adhérer" plus clair** : Pour non connecté → "S'inscrire pour adhérer" au lieu de juste "Adhérer"
- [ ] **Ajouter un compteur social proof** : "Rejoignez X membres" ou "X événements organisés" (si données disponibles)

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Créer les pages manquantes du footer** : Pages statiques pour FAQ, Contact, CGU, Confidentialité, Qui sommes-nous, Équipe (ou rediriger vers page Association)
- [ ] **Implémenter newsletter fonctionnelle** : Formulaire footer avec intégration service email (SendGrid, Mailchimp, etc.)
- [ ] **Lier réseaux sociaux** : Ajouter les vraies URLs des réseaux sociaux de l'association
- [ ] **Section "Pourquoi nous rejoindre ?"** : 3-4 cards avec valeurs (Convivialité, Sécurité, Dynamisme, Respect) + icônes
- [ ] **Section "Derniers événements"** : Carrousel ou grille avec 3-4 derniers événements passés avec photos
- [ ] **Section "Tarifs d'adhésion"** : Tableau simple avec 3 tarifs (10€, 56,55€, 58€) + CTA "Adhérer maintenant"
- [ ] **Améliorer le message vide** : Si aucun événement, proposer "Soyez le premier à créer un événement" (si organisateur) ou "Inscrivez-vous pour être notifié"

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Témoignages membres** : Section avec 2-3 témoignages + photos
- [ ] **Galerie photos** : Carrousel avec photos d'événements passés
- [ ] **Carte interactive** : Carte avec points de départ des événements récurrents

---

### 📍 **Parcours 2 : Inscription (Nouveau Membre)**

**Objectif** : Créer un compte et devenir membre

**Étapes** :
1. Clic sur "S'inscrire" / "Connexion"
2. Remplissage du formulaire d'inscription
3. Validation email (si configuré)
4. Connexion initiale
5. Complétion du profil (optionnel)

**Points de friction potentiels** :
- [ ] Formulaire d'inscription trop long ?
- [ ] Champs obligatoires clairement indiqués ?
- [ ] Messages d'erreur clairs et utiles ?
- [ ] Processus de validation email fluide ?
- [ ] Redirection après inscription logique ?
**Récit du parcours actuel** :
L'utilisateur clique sur "S'inscrire" depuis la navbar ou la homepage. Il arrive sur un formulaire centré dans une card avec icône "person-plus". Le formulaire demande : Prénom (obligatoire), Nom (optionnel), Email (obligatoire), Téléphone (optionnel), Mot de passe (obligatoire, avec indication "Au moins X caractères"), Confirmation mot de passe (obligatoire), Biographie (optionnel, avec aide contextuelle). Les champs obligatoires sont marqués par `required: true` et les optionnels par "(optionnel)" dans le label. Un lien "Déjà un compte ? Connectez-vous" est présent en bas. Après soumission réussie, Devise redirige vers `root_path` (homepage) avec un message de succès. Aucune validation email n'est configurée (pas de `:confirmable` dans Devise).

**Points forts actuels** :
- ✅ Formulaire clair et centré, visuellement agréable
- ✅ Champs optionnels clairement indiqués avec "(optionnel)"
- ✅ Aide contextuelle pour mot de passe (longueur minimale)
- ✅ Aide contextuelle pour biographie
- ✅ Lien vers connexion visible
- ✅ Icône visuelle pour identifier la page

**Points de friction identifiés** :
- [ ] **Pas d'indication visuelle des champs obligatoires** : Seulement `required: true` (HTML5), pas d'astérisque `*` visuel
- [ ] **Validation en temps réel absente** : L'utilisateur ne sait si l'email est valide/unique qu'après soumission
- [ ] **Messages d'erreur génériques** : Devise affiche des erreurs standard, pas toujours claires (ex: "Email has already been taken")
- [ ] **Pas de force du mot de passe visible** : Indication de longueur mais pas de force (faible/moyen/fort)
- [ ] **Redirection après inscription vers homepage** : Pas de message de bienvenue personnalisé ni d'orientation vers prochaines étapes
- [ ] **Pas de validation email** : Compte actif immédiatement, pas de vérification email
- [ ] **Pas de guide "Prochaines étapes"** : Après inscription, l'utilisateur ne sait pas quoi faire (voir événements ? compléter profil ?)

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Ajouter astérisques `*` aux champs obligatoires** : Visuellement clair (Prénom*, Email*, Mot de passe*)
- [ ] **Améliorer les messages d'erreur Devise** : Traduire/customiser les messages (ex: "Cet email est déjà utilisé" au lieu de "Email has already been taken")
- [ ] **Message de bienvenue après inscription** : Toast/alerte "Bienvenue [Prénom] ! Découvrez les événements à venir" avec lien vers événements
- [ ] **Indicateur de force du mot de passe** : Barre de progression visuelle (faible/moyen/fort) avec JavaScript

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Validation email en temps réel** : Vérifier si email existe déjà via AJAX avant soumission
- [ ] **Page de bienvenue après inscription** : Redirection vers `/welcome` avec guide "Prochaines étapes" (voir événements, compléter profil, adhérer)
- [ ] **Activation validation email (Devise :confirmable)** : Envoyer email de confirmation, compte inactif jusqu'à confirmation
- [ ] **Améliorer la validation téléphone** : Format français (06 12 34 56 78) avec masque de saisie
- [ ] **Indicateur de progression du formulaire** : Barre de progression "Étape 1/1" (pour préparer futures étapes)

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Inscription en plusieurs étapes** : Étape 1 (identité) → Étape 2 (profil) → Étape 3 (préférences)
- [ ] **Inscription via réseaux sociaux** : OAuth (Google, Facebook) pour simplifier
- [ ] **Vérification téléphone (SMS)** : Optionnel pour sécurité renforcée
- [ ] **Onboarding interactif** : Tour guidé de l'application après première connexion

---

### 📍 **Parcours 3 : Découverte des Événements (Membre Connecté)**

**Objectif** : Trouver un événement qui l'intéresse

**Étapes** :
1. Connexion à l'application
2. Navigation vers "Événements"
3. Consultation de la liste des événements
4. Filtrage/recherche (si disponible)
5. Consultation des détails d'un événement

**Points de friction potentiels** :
- [ ] Liste des événements claire et lisible ?
- [ ] Informations essentielles visibles (date, heure, lieu, places restantes) ?
- [ ] Filtres/recherche fonctionnels et intuitifs ?
- [ ] Tri des événements logique (par date, popularité) ?
- [ ] Pagination si beaucoup d'événements ?
- [ ] Indicateur visuel pour événements complets ?

**Récit du parcours actuel** :
L'utilisateur clique sur "Événements" dans la navbar. Il arrive sur une page avec banner "Nos Événements". La page est structurée en 3 sections : 1) "Prochain rendez-vous" (featured event) avec card détaillée (image, date, lieu, distance, durée, badges d'inscription, actions), 2) "À venir" avec grille de cards (3 colonnes responsive), 3) "Événements passés" (limite 6). Chaque card affiche : image, date en badge, titre cliquable, infos essentielles (date/heure, lieu, distance, durée), description tronquée (100 caractères), badges (inscrits, places restantes avec code couleur : vert si >5, orange si ≤5, rouge si complet), boutons d'action (S'inscrire, Voir plus, Calendrier). Les événements sont triés par date (prochains en premier). Aucun filtre ni recherche n'est disponible. Pas de pagination (tous les événements à venir sont affichés).

**Points forts actuels** :
- ✅ Structure claire avec sections distinctes (featured, à venir, passés)
- ✅ Informations essentielles visibles sur chaque card (date, lieu, distance, durée)
- ✅ Badges visuels pour statut (complet, places restantes, inscrit)
- ✅ Code couleur intuitif (vert/orange/rouge pour places)
- ✅ Responsive (grille 3 colonnes → 2 → 1 selon écran)
- ✅ Tri logique (prochains événements en premier)

**Points de friction identifiés** :
- [ ] **Pas de filtres** : Impossible de filtrer par date, route, niveau, distance
- [ ] **Pas de recherche** : Impossible de chercher un événement par mot-clé
- [ ] **Pas de pagination** : Si beaucoup d'événements, la page devient longue
- [ ] **Pas de tri personnalisé** : Seulement tri par date, pas par popularité, distance, etc.
- [ ] **Pas de vue calendrier** : Seulement vue liste, pas de vue calendrier mensuel
- [ ] **Lieu tronqué dans les cards** : Le lieu est tronqué à 35 caractères, peut être incomplet
- [ ] **Pas d'indication "Nouveau"** : Aucun badge pour les événements créés récemment

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Ajouter badge "Nouveau"** : Badge pour événements créés dans les 7 derniers jours
- [ ] **Améliorer troncature lieu** : Augmenter à 50 caractères ou afficher sur 2 lignes
- [ ] **Ajouter compteur d'événements** : "X événements à venir" visible en haut de section
- [ ] **Lien "Voir tous les événements passés"** : Si >6 événements passés, lien vers page dédiée

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Barre de recherche** : Recherche par titre, description, lieu (AJAX)
- [ ] **Filtres basiques** : Filtres par date (cette semaine, ce mois, prochains 3 mois), par route, par niveau
- [ ] **Pagination** : Pagination avec Kaminari/Pagy (10-15 événements par page)
- [ ] **Tri personnalisé** : Dropdown "Trier par" (Date, Popularité, Distance, Nouveautés)
- [ ] **Vue calendrier** : Toggle vue liste/calendrier avec FullCalendar (vue mensuelle)
- [ ] **Filtres avancés** : Filtres combinés (date + route + niveau) avec tags actifs visibles

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Carte interactive** : Carte avec points des événements, filtrage par zone géographique
- [ ] **Suggestions personnalisées** : "Événements qui pourraient vous intéresser" basé sur historique
- [ ] **Filtres sauvegardés** : Permettre de sauvegarder des filtres favoris
- [ ] **Export calendrier global** : Export iCal de tous les événements à venir (pas seulement un par un)

---

### 📍 **Parcours 4 : Inscription à un Événement**

**Objectif** : S'inscrire à un événement

**Étapes** :
1. Consultation de la page événement
2. Vérification des informations (date, heure, lieu, niveau)
3. Clic sur "S'inscrire"
4. Confirmation (modal Bootstrap)
5. Activation/désactivation du rappel (optionnel)
6. Confirmation de l'inscription
7. Réception email de confirmation

**Points de friction potentiels** :
- [ ] Modal de confirmation claire et rassurante ?
- [ ] Option de rappel visible et compréhensible ?
- [ ] Message de succès clair après inscription ?
- [ ] Gestion des erreurs (événement plein, déjà inscrit) ?
- [ ] Feedback visuel immédiat (bouton désactivé si plein) ?
- [ ] Indication du nombre de places restantes claire ?

**Récit du parcours actuel** :
L'utilisateur consulte la page événement avec hero image, badges (inscrits, places restantes), détails (Quand, Rendez-vous avec GPS/Google Maps/Waze, Tarif, Organisateur), description complète. Si déjà inscrit, alerte rappel (activé/désactivé) avec bouton toggle. Bouton primaire "S'inscrire" (grand, couleur) visible si non inscrit et événement non plein. Clic sur "S'inscrire" → modal Bootstrap s'ouvre avec titre "Confirmer votre inscription", texte de confirmation, checkbox "Recevoir un rappel par email la veille à 19h" (cochée par défaut), info "Vous recevrez une confirmation par email et pourrez annuler votre inscription à tout moment", boutons "Annuler" et "Confirmer l'inscription". Après confirmation → redirection vers page événement avec message flash "Inscription confirmée." + email de confirmation envoyé. Si événement plein → bouton désactivé "Cet événement est complet". Si déjà inscrit → bouton "Se désinscrire" avec confirmation Turbo.

**Points forts actuels** :
- ✅ Modal de confirmation claire avec toutes les infos nécessaires
- ✅ Option rappel visible et compréhensible (cochée par défaut)
- ✅ Message de succès après inscription
- ✅ Gestion gracieuse des erreurs (bouton désactivé si plein)
- ✅ Badges visuels pour places restantes (vert/orange/rouge)
- ✅ Alerte rappel visible sur page événement après inscription
- ✅ Bouton toggle rappel facilement accessible

**Points de friction identifiés** :
- [ ] **Pas de résumé dans la modal** : La modal ne rappelle pas les infos essentielles (date, heure, lieu) avant confirmation
- [ ] **Pas de prévisualisation email** : L'utilisateur ne sait pas à quoi ressemblera l'email de confirmation
- [ ] **Message de succès générique** : "Inscription confirmée" sans personnalisation (pas de "À bientôt le [date] !")
- [ ] **Pas de confirmation visuelle immédiate** : Après clic "Confirmer", la modal se ferme mais pas de feedback pendant le chargement
- [ ] **Pas d'indication "Presque complet"** : Si ≤5 places, pas d'alerte dans la modal pour inciter à s'inscrire rapidement
- [ ] **Pas de rappel des conditions** : Modal ne mentionne pas les conditions d'annulation (jusqu'à quand peut-on annuler ?)

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Ajouter résumé dans modal** : Afficher date, heure, lieu dans la modal avant confirmation
- [ ] **Message de succès personnalisé** : "Inscription confirmée ! À bientôt le [date] à [heure]" au lieu de message générique
- [ ] **Indicateur de chargement** : Spinner/loader pendant soumission du formulaire dans la modal
- [ ] **Alerte "Presque complet"** : Si ≤5 places, alerte dans la modal "Plus que X places disponibles !"

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Prévisualisation email** : Aperçu de l'email de confirmation dans la modal (optionnel, bouton "Aperçu")
- [ ] **Conditions d'annulation claires** : Mentionner dans la modal "Vous pouvez annuler jusqu'à [X heures] avant l'événement"
- [ ] **Confirmation en deux étapes** : Étape 1 (modal) → Étape 2 (page de confirmation avec QR code ?)
- [ ] **Rappel des informations GPS** : Si coordonnées GPS disponibles, rappeler dans la modal avec lien Google Maps/Waze
- [ ] **Notification push (optionnel)** : Demander permission pour notifications push en plus de l'email

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Inscription avec paiement** : Si événement payant, intégrer le paiement dans le flux d'inscription
- [ ] **Inscription groupée** : Permettre d'inscrire plusieurs personnes (famille, amis) en une fois
- [ ] **Liste d'attente** : Si événement complet, proposer de s'inscrire sur liste d'attente
- [ ] **QR code de confirmation** : Générer un QR code unique pour chaque inscription (vérification à l'arrivée)

---

### 📍 **Parcours 5 : Gestion de Mes Inscriptions**

**Objectif** : Voir et gérer ses inscriptions aux événements

**Étapes** :
1. Navigation vers "Mes sorties"
2. Consultation de la liste des événements inscrits
3. Consultation des détails d'un événement
4. Désinscription si nécessaire
5. Activation/désactivation du rappel

**Points de friction potentiels** :
- [ ] Liste "Mes sorties" claire et organisée ?
- [ ] Tri logique (prochains événements en premier) ?
- [ ] Informations essentielles visibles (date, statut) ?
- [ ] Bouton de désinscription facilement accessible ?
- [ ] Confirmation avant désinscription ?
- [ ] Indication du statut du rappel visible ?

**Récit du parcours actuel** :
L'utilisateur clique sur "Mes sorties" dans le menu dropdown (icône calendrier). Il arrive sur une page avec titre "Mes sorties" et description "Retrouvez ici toutes les sorties auxquelles vous êtes inscrit(e). Gérez vos inscriptions en un clic." Un bouton "Voir toutes les sorties" permet de revenir à la liste complète. Si des inscriptions existent, affichage en grille (même système de cards que la liste événements) avec : image, date, titre, infos essentielles, badges (inscrits, places restantes, "Vous êtes inscrit(e)"), boutons d'action (Calendrier, Se désinscrire, Voir plus). Les événements sont triés par date (prochains en premier) et seuls les attendances actives sont affichées. Si aucune inscription → message "Vous n'êtes inscrit(e) à aucune sortie pour le moment" avec lien "Découvrir les événements". La désinscription se fait via bouton "Se désinscrire" avec confirmation Turbo "Annuler votre inscription ?". Pas de distinction visuelle entre événements à venir et passés. Pas de filtre ni de recherche. Pas de pagination.

**Points forts actuels** :
- ✅ Page claire avec titre et description
- ✅ Tri logique (prochains événements en premier)
- ✅ Utilisation du même système de cards que la liste événements (cohérence)
- ✅ Bouton de désinscription accessible sur chaque card
- ✅ Confirmation avant désinscription (Turbo confirm)
- ✅ Message rassurant si aucune inscription
- ✅ Lien vers liste complète des événements

**Points de friction identifiés** :
- [ ] **Pas de distinction visuelle passé/à venir** : Tous les événements sont affichés de la même manière, pas de séparation
- [ ] **Pas de filtre** : Impossible de filtrer par date (à venir, passés), par statut rappel
- [ ] **Pas de recherche** : Impossible de chercher un événement spécifique dans ses inscriptions
- [ ] **Pas de pagination** : Si beaucoup d'inscriptions, la page devient longue
- [ ] **Pas d'indication "Événement passé"** : Les événements passés ne sont pas clairement identifiés
- [ ] **Pas de vue calendrier** : Seulement vue liste, pas de vue calendrier de ses sorties
- [ ] **Statut rappel non visible dans la liste** : L'utilisateur doit cliquer sur chaque événement pour voir le statut du rappel

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Séparer événements à venir et passés** : Section "À venir" et "Passés" avec compteurs
- [ ] **Badge "Passé"** : Badge distinctif pour les événements passés (gris, avec icône)
- [ ] **Indicateur rappel dans la liste** : Badge "Rappel activé" / "Rappel désactivé" sur chaque card
- [ ] **Compteur d'inscriptions** : "X sorties à venir" visible en haut de page

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Filtres basiques** : Filtres par date (à venir, passés, ce mois), par statut rappel
- [ ] **Pagination** : Pagination avec Kaminari/Pagy (10-15 événements par page)
- [ ] **Vue calendrier** : Toggle vue liste/calendrier avec FullCalendar (vue mensuelle de ses sorties)
- [ ] **Actions en masse** : Checkbox pour sélectionner plusieurs événements et désinscription en masse
- [ ] **Export calendrier global** : Export iCal de toutes ses inscriptions en une fois
- [ ] **Tri personnalisé** : Dropdown "Trier par" (Date, Nom, Distance)

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Statistiques personnelles** : Graphique "Nombre de sorties par mois", "Kilomètres parcourus"
- [ ] **Historique complet** : Voir toutes les sorties (y compris annulées) avec filtre par statut
- [ ] **Rappels personnalisés** : Paramètres globaux pour rappels (toujours activer, désactiver, etc.)
- [ ] **Partage de ses sorties** : Lien public pour partager sa liste de sorties à venir

---

### 📍 **Parcours 6 : Création d'un Événement (Organisateur)**

**Objectif** : Créer un nouvel événement

**Étapes** :
1. Navigation vers "Événements" → "Créer un événement"
2. Remplissage du formulaire (titre, description, date, heure, route, etc.)
3. Sélection d'une route existante ou création d'une nouvelle
4. Validation du formulaire
5. Publication de l'événement (ou sauvegarde en brouillon)
6. Vérification de l'événement créé

**Points de friction potentiels** :
- [ ] Formulaire de création clair et structuré ?
- [ ] Champs obligatoires clairement indiqués ?
- [ ] Aide contextuelle pour les champs complexes (niveau, distance) ?
- [ ] Gestion des routes (création/sélection) intuitive ?
- [ ] Prévisualisation avant publication ?
- [ ] Messages d'erreur clairs et actionnables ?
- [ ] Workflow de modération clair (draft → published) ?

**Récit du parcours actuel** :
L'organisateur clique sur "Créer un événement" dans la navbar (visible uniquement si rôle ORGANIZER+). Il arrive sur un formulaire centré dans une card avec icône "calendar-event". Le formulaire demande : Titre (obligatoire, max 140 caractères), Parcours associé (dropdown avec routes existantes ou "Sans parcours"), Niveau (obligatoire, 4 options : Débutant, Intermédiaire, Confirmé, Tous niveaux), Distance (obligatoire, nombre avec décimales), Date/heure de début (datetime-local), Durée (minutes, min 30), Max participants (0 = illimité, avec aide contextuelle), Prix (€, obligatoire), Lieu/Point de rendez-vous (obligatoire, max 255 caractères), Coordonnées GPS (optionnel, collapsed par défaut avec lien Google Maps), Image de couverture (URL optionnel), Description détaillée (obligatoire, textarea 5 lignes). Si parcours sélectionné → pré-remplissage automatique niveau et distance via JavaScript. Alerte info visible : "En attente de validation : Votre événement sera soumis à validation par un modérateur avant d'être publié." Après soumission → événement créé en statut "draft" → redirection vers page événement avec message "Événement créé avec succès. Il est en attente de validation par un modérateur." Les erreurs de validation s'affichent en haut du formulaire avec liste détaillée.

**Points forts actuels** :
- ✅ Formulaire structuré et clair avec sections logiques
- ✅ Champs obligatoires marqués avec astérisque rouge `*`
- ✅ Aide contextuelle pour champs complexes (max participants, GPS, image)
- ✅ Pré-remplissage automatique niveau/distance si parcours sélectionné
- ✅ Coordonnées GPS optionnelles (collapsed, pas intrusif)
- ✅ Workflow de modération clair (draft → validation modérateur)
- ✅ Messages d'erreur détaillés avec liste

**Points de friction identifiés** :
- [ ] **Formulaire long** : Beaucoup de champs, peut être intimidant pour nouveaux organisateurs
- [ ] **Pas de sauvegarde automatique** : Si erreur de validation, tous les champs sont perdus
- [ ] **Pas de prévisualisation** : Impossible de voir à quoi ressemblera l'événement avant soumission
- [ ] **Pas de création de route depuis le formulaire** : Doit créer la route ailleurs avant de l'utiliser
- [ ] **Pas de validation en temps réel** : L'utilisateur ne sait si les champs sont valides qu'après soumission
- [ ] **Pas d'aide pour coordonnées GPS** : Lien vers Google Maps mais pas d'intégration directe
- [ ] **Pas de template/réutilisation** : Impossible de dupliquer un événement existant
- [ ] **Pas d'indication de progression** : Pas de barre de progression "Étape X/Y"

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Sauvegarde automatique (localStorage)** : Sauvegarder les champs dans localStorage pendant la saisie
- [ ] **Validation en temps réel** : Vérifier les champs au blur (email format, dates logiques, etc.)
- [ ] **Indicateur de progression** : Barre "Étape 1/1" ou compteur de champs remplis
- [ ] **Message de confirmation avant soumission** : "Votre événement sera en attente de validation. Continuer ?"

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Formulaire en plusieurs étapes** : Étape 1 (Infos de base) → Étape 2 (Détails) → Étape 3 (Options)
- [ ] **Prévisualisation événement** : Bouton "Aperçu" qui montre la card événement telle qu'elle apparaîtra
- [ ] **Création route depuis formulaire** : Modal "Créer un nouveau parcours" directement depuis le formulaire
- [ ] **Intégration Google Maps** : Carte interactive pour sélectionner coordonnées GPS (au lieu de saisie manuelle)
- [ ] **Duplication d'événement** : Bouton "Dupliquer" sur événement existant pour créer un nouveau basé sur celui-ci
- [ ] **Templates d'événements** : Templates pré-remplis (ex: "Rando vendredi soir", "Initiation samedi matin")
- [ ] **Validation côté client** : Validation HTML5 + JavaScript avant soumission (éviter rechargement page)

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Éditeur WYSIWYG pour description** : Éditeur riche (Trix, TinyMCE) pour formater la description
- [ ] **Upload image direct** : Upload d'image depuis l'ordinateur (Active Storage) au lieu de URL
- [ ] **Planification récurrente** : Créer plusieurs événements à la fois (ex: tous les vendredis du mois)
- [ ] **Aide contextuelle avancée** : Tooltips avec exemples concrets pour chaque champ
- [ ] **Historique de modifications** : Voir l'historique des modifications d'un événement (audit log)

---

### 📍 **Parcours 7 : Achat en Boutique**

**Objectif** : Acheter un produit de la boutique

**Étapes** :
1. Navigation vers "Boutique"
2. Consultation du catalogue
3. Sélection d'un produit
4. Choix des variantes (taille, couleur)
5. Ajout au panier
6. Consultation du panier
7. Passage à la caisse (checkout)
8. Confirmation de commande

**Points de friction potentiels** :
- [ ] Catalogue clair et organisé par catégories ?
- [ ] Images produits de qualité et visibles ?
- [ ] Sélection des variantes intuitive ?
- [ ] Indication du stock disponible claire ?
- [ ] Panier accessible facilement (icône avec compteur) ?
- [ ] Processus de checkout simple et sécurisé ?
- [ ] Confirmation de commande rassurante ?

**Récit du parcours actuel** :
L'utilisateur clique sur "Boutique" dans la navbar. Il arrive sur une page avec titre "Boutique" et grille de produits (cards). Chaque card affiche : image produit, badge "En stock" ou "Rupture", titre produit, description tronquée, dropdowns pour sélectionner taille/couleur (si variantes), prix (ou "À partir de X€" si plusieurs prix), bouton "Ajouter au panier" (désactivé si variante non sélectionnée ou rupture). JavaScript gère la sélection de variantes : si taille ET couleur sélectionnées → variante trouvée → bouton activé + prix mis à jour. Clic sur card → page produit détaillée avec : breadcrumb, image principale, titre, catégorie, description, prix, sélecteurs taille/couleur, quantité (boutons +/-), stock affiché dynamiquement, bouton "Ajouter au panier", lien "Voir le panier". Après ajout → redirection vers panier avec message "Article ajouté au panier." Le panier affiche : liste des articles (image, nom, SKU, prix unitaire, quantité modifiable avec boutons +/- et validation, sous-total, bouton supprimer), sous-total, boutons "Continuer les achats" et "Confirmer et payer" (ou "Se connecter pour commander" si non connecté). Si connecté → checkout avec : récapitulatif articles, section don (radio 0€/2€/3€/5€/personnalisé), sous-total + don = total, boutons "Modifier le panier" et "Payer Via HelloAsso*", info box HelloAsso. Après paiement → commande créée → redirection vers page commande avec : numéro commande, statut (badge coloré), date/heure, nombre d'articles, total, liste articles, bouton "Annuler" (si statut pending/preparation).

**Points forts actuels** :
- ✅ Catalogue clair avec grille responsive
- ✅ Sélection variantes intuitive (dropdowns taille/couleur)
- ✅ Mise à jour dynamique prix/stock selon variante sélectionnée
- ✅ Panier accessible via icône navbar avec compteur
- ✅ Gestion quantité dans panier avec validation
- ✅ Section don optionnelle bien intégrée
- ✅ Confirmation commande claire avec statut visible
- ✅ Gestion stock automatique (ajustement quantité si stock insuffisant)

**Points de friction identifiés** :
- [ ] **Pas de filtres par catégories** : Tous les produits affichés, pas de filtrage par catégorie
- [ ] **Pas de recherche** : Impossible de chercher un produit par nom
- [ ] **Pas de tri** : Impossible de trier par prix, nom, popularité
- [ ] **Images produits parfois manquantes** : Si pas d'image_url, icône générique peu attrayante
- [ ] **Pas de zoom sur image produit** : Impossible d'agrandir l'image en détail
- [ ] **Pas de galerie d'images** : Une seule image par produit, pas de vues multiples
- [ ] **Panier en session uniquement** : Panier perdu si cookie expiré (pas de persistance pour utilisateurs connectés)
- [ ] **Pas de sauvegarde panier** : Si déconnexion, panier perdu
- [ ] **Checkout sans adresse de livraison** : Pas de formulaire d'adresse (peut-être prévu pour HelloAsso ?)
- [ ] **Pas de récapitulatif avant paiement** : Le don est affiché mais pas intégré dans la commande finale

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Filtres par catégories** : Sidebar ou tabs avec catégories (Rollers, Protections, Accessoires)
- [ ] **Barre de recherche** : Recherche par nom produit (AJAX)
- [ ] **Améliorer image par défaut** : Image placeholder plus attrayante si pas d'image_url
- [ ] **Zoom sur image produit** : Lightbox pour agrandir l'image au clic
- [ ] **Message "Article ajouté" plus visible** : Toast/notification persistante au lieu de simple redirect

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Tri des produits** : Dropdown "Trier par" (Prix croissant, Prix décroissant, Nom A-Z, Popularité)
- [ ] **Galerie d'images** : Carrousel avec plusieurs images par produit (si disponibles)
- [ ] **Panier persistant pour utilisateurs connectés** : Sauvegarder panier en DB, fusionner avec session à la connexion
- [ ] **Sauvegarde panier avant déconnexion** : Sauvegarder automatiquement le panier en DB si utilisateur connecté
- [ ] **Récapitulatif avant paiement** : Page intermédiaire "Récapitulatif" avec adresse de livraison (si nécessaire)
- [ ] **Intégration don dans commande** : Le don doit être enregistré dans la commande, pas seulement affiché
- [ ] **Suggestions produits** : "Produits similaires" ou "Autres clients ont aussi acheté" sur page produit

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Comparaison de produits** : Permettre de comparer 2-3 produits côte à côte
- [ ] **Liste de souhaits (Wishlist)** : Permettre d'ajouter des produits à une liste de souhaits
- [ ] **Avis clients** : Système d'avis et notes sur les produits
- [ ] **Historique de navigation** : "Produits récemment consultés"
- [ ] **Notifications stock** : "Me prévenir quand ce produit sera de nouveau en stock"
- [ ] **Codes promo** : Système de codes promotionnels

---

### 📍 **Parcours 8 : Administration (Admin)**

**Objectif** : Gérer l'application via ActiveAdmin

**Étapes** :
1. Connexion en tant qu'admin
2. Navigation vers `/admin`
3. Consultation du dashboard
4. Gestion des événements (modération, validation)
5. Gestion des utilisateurs
6. Consultation des statistiques

**Points de friction potentiels** :
- [ ] Dashboard admin informatif et actionnable ?
- [ ] Navigation admin claire et logique ?
- [ ] Filtres et recherches efficaces ?
- [ ] Actions en masse (bulk actions) disponibles ?
- [ ] Exports CSV/PDF fonctionnels ?
- [ ] Statistiques visuelles et compréhensibles ?

**Récit du parcours actuel** :
L'admin clique sur "Administration" dans le menu dropdown (visible si rôle ADMIN/SUPERADMIN). Il arrive sur `/admin` (ActiveAdmin) avec sidebar de navigation : Dashboard, Événements, Routes, Inscriptions, Demandes d'organisateur, Partenaires, Messages de contact, Logs d'audit, Utilisateurs, Rôles, Produits, Commandes. Le Dashboard est vide (blank slate avec message "Welcome to ActiveAdmin"). Navigation vers "Événements" → liste avec colonnes : ID, Titre, Statut (badge coloré), Date début, Durée, Max participants, Inscriptions, Route, Créateur, Prix, Actions. Scopes disponibles : "Tous", "À venir", "Publiés", "En attente de validation" (par défaut), "Refusés", "Annulés". Filtres : titre, statut, route, créateur, date début, date création. Clic sur événement → page détail avec : tableau attributs (titre, statut, dates, participants, route, prix, lieu, GPS, description), panel "Inscriptions" avec tableau (utilisateur, statut, paiement, date). Bouton "Modifier" → formulaire avec sections : Informations générales, Tarification, Point de rendez-vous. Possibilité de changer statut (draft → published pour valider). Même structure pour autres resources (Users, Orders, Products, etc.). Pas de bulk actions visibles. Pas d'exports CSV/PDF. Pas de statistiques sur le dashboard.

**Points forts actuels** :
- ✅ Interface ActiveAdmin standardisée et professionnelle
- ✅ Navigation claire avec sidebar
- ✅ Filtres et scopes fonctionnels sur Events
- ✅ Panel "Inscriptions" dans détail événement (utile)
- ✅ Statuts visuels avec badges colorés
- ✅ Intégration Pundit pour autorisations
- ✅ Formulaire de modification complet avec sections

**Points de friction identifiés** :
- [ ] **Dashboard vide** : Pas de statistiques, pas d'actions rapides, pas d'informations utiles
- [ ] **Pas de bulk actions** : Impossible de modifier plusieurs événements en une fois (ex: publier 10 événements)
- [ ] **Pas d'exports** : Impossible d'exporter les données (CSV, PDF) pour analyse externe
- [ ] **Pas de statistiques** : Aucune vue d'ensemble (nombre d'événements, utilisateurs, commandes, revenus)
- [ ] **Pas de recherche globale** : Pas de barre de recherche qui cherche dans toutes les resources
- [ ] **Pas d'actions rapides** : Pas de boutons "Publier", "Refuser" directement dans la liste
- [ ] **Pas de vue "À valider"** : Scope "En attente de validation" existe mais pas de vue dédiée avec actions rapides
- [ ] **Navigation peut être longue** : Beaucoup de resources dans le menu, pas de regroupement

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible)**
- [ ] **Dashboard avec statistiques basiques** : Cards avec compteurs (Événements à valider, Utilisateurs, Commandes, Revenus)
- [ ] **Actions rapides dans liste Events** : Boutons "Publier", "Refuser" directement dans la colonne Actions
- [ ] **Vue "À valider" améliorée** : Panel dédié sur dashboard avec liste événements en attente + actions rapides
- [ ] **Exports CSV basiques** : Bouton "Exporter CSV" sur chaque resource (ActiveAdmin le supporte nativement)

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Bulk actions** : Sélectionner plusieurs événements → "Publier en masse", "Refuser en masse", "Changer statut"
- [ ] **Dashboard complet** : Graphiques (événements par mois, inscriptions par événement, revenus), liste événements à valider, dernières commandes
- [ ] **Recherche globale** : Barre de recherche qui cherche dans Events, Users, Orders simultanément
- [ ] **Regroupement menu** : Menu groupé (ex: "Événements" → Events, Routes, Attendances)
- [ ] **Exports avancés** : Exports CSV personnalisés avec colonnes choisies, exports PDF pour rapports
- [ ] **Filtres sauvegardés** : Permettre de sauvegarder des filtres fréquents (ex: "Événements ce mois")

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Tableau de bord personnalisable** : Admin peut choisir quels widgets afficher
- [ ] **Notifications admin** : Alertes pour événements à valider, commandes en attente, messages non lus
- [ ] **Workflow de modération** : Interface dédiée pour modérer les événements (approve/reject avec commentaires)
- [ ] **Rapports automatiques** : Génération automatique de rapports (hebdomadaire, mensuel) par email
- [ ] **Audit trail visuel** : Voir l'historique des modifications d'un événement/commande avec qui/quand

---

### 📍 **Parcours 9 : Navigation via Footer (Tous Utilisateurs)**

**Objectif** : Accéder aux pages d'information via le footer

**Étapes** :
1. Scroll vers le bas de la page
2. Consultation du footer
3. Clic sur un lien d'intérêt (FAQ, Contact, CGU, etc.)
4. Arrivée sur la page demandée

**Récit du parcours actuel** :
L'utilisateur scroll vers le bas de n'importe quelle page et découvre un footer complet avec 4 colonnes : "À propos" (Qui sommes-nous, Équipe, Carrières, Blog), "Événements" (Parcourir, Catégories, Villes, Créer un événement), "Support" (FAQ, Contact, CGU, Confidentialité), "Suivez-nous" (réseaux sociaux + newsletter). Tous les liens pointent vers `#` (non fonctionnels). Clic sur un lien → rien ne se passe (reste sur la même page) ou scroll vers le haut. Newsletter : formulaire présent mais non fonctionnel (pas de traitement backend). Réseaux sociaux : tous pointent vers `#`.

**Points forts actuels** :
- ✅ Footer visuellement complet et professionnel
- ✅ Structure claire avec 4 sections logiques
- ✅ Design cohérent avec le reste de l'application
- ✅ Responsive (colonnes adaptées mobile)

**Points de friction identifiés** :
- [ ] **⚠️ CRITIQUE : Tous les liens sont morts** : Tous les liens pointent vers `#`, créant une frustration majeure
- [ ] **Newsletter non fonctionnelle** : Formulaire présent mais pas de traitement backend
- [ ] **Réseaux sociaux non liés** : Tous pointent vers `#` au lieu des vraies URLs
- [ ] **Pages manquantes** : Aucune page pour FAQ, Contact, CGU, Confidentialité, Qui sommes-nous, Équipe, Carrières, Blog
- [ ] **Liens redondants** : "Parcourir" et "Créer un événement" existent déjà dans la navbar mais pointent vers `#` dans le footer
- [ ] **Pas de feedback** : Clic sur lien mort → aucun message d'erreur ou indication que la page n'existe pas

**Améliorations identifiées** :

#### 🟢 **Quick Wins (Impact Haut, Effort Faible) - URGENT**
- [ ] **⚠️ URGENT : Masquer temporairement les sections non implémentées** : Utiliser `display: none` ou conditionnel Rails pour masquer les liens morts jusqu'à implémentation
- [ ] **⚠️ URGENT : Corriger les liens existants** : "Parcourir" → `/events`, "Créer un événement" → `/events/new` (si organisateur)
- [ ] **Désactiver newsletter temporairement** : Masquer le formulaire ou ajouter message "Bientôt disponible"

#### 🟡 **Améliorations Importantes (Impact Haut, Effort Moyen)**
- [ ] **Créer pages statiques essentielles** : FAQ, Contact (formulaire), CGU, Confidentialité (RGPD)
- [ ] **Créer pages "À propos"** : Qui sommes-nous (rediriger vers `/association` ou créer section dédiée), Équipe (si applicable)
- [ ] **Implémenter newsletter fonctionnelle** : Backend avec modèle `NewsletterSubscription`, intégration service email (SendGrid, Mailchimp)
- [ ] **Lier réseaux sociaux** : Ajouter vraies URLs Facebook, Instagram, etc. dans variables d'environnement
- [ ] **Créer page Blog** : Si blog prévu, créer structure de base (ou masquer le lien)
- [ ] **Gérer liens "Carrières" et "Villes"** : Si non applicables, masquer ou créer pages placeholder

#### 🔴 **Améliorations Futures (Impact Moyen, Effort Élevé)**
- [ ] **Système de blog complet** : Si blog prévu, implémenter avec articles, catégories, commentaires
- [ ] **Page Carrières** : Si recrutement prévu, créer page avec offres d'emploi
- [ ] **Filtres "Catégories" et "Villes"** : Si filtres événements prévus, créer pages dédiées
- [ ] **Newsletter avancée** : Segmentation, templates, analytics

---

## 🔍 Analyse des Points de Friction

### **Critères d'Analyse**

Pour chaque parcours, analyser :
1. **Clarté** : L'utilisateur comprend-il ce qu'il doit faire ?
2. **Efficacité** : Le nombre d'étapes est-il minimal ?
3. **Feedback** : L'utilisateur reçoit-il des retours clairs à chaque étape ?
4. **Erreurs** : Les erreurs sont-elles gérées gracieusement ?
5. **Accessibilité** : L'interface est-elle accessible (clavier, screen reader) ?
6. **Mobile** : L'expérience mobile est-elle optimale ?

---

## 📊 Matrice de Priorisation des Améliorations

### **Critères de Priorisation**

- **Impact Utilisateur** : Haute / Moyenne / Basse
- **Effort** : Faible / Moyen / Élevé
- **Urgence** : Critique / Important / Amélioration

### **Matrice Impact vs Effort**

```
        │ Faible Effort │ Moyen Effort │ Élevé Effort
────────┼───────────────┼──────────────┼─────────────
Impact  │               │              │
Haute   │ 🟢 Quick Win  │ 🟡 Priorité  │ 🔴 Si temps
        │               │              │
Impact  │               │              │
Moyenne │ 🟢 Quick Win  │ 🟡 Si temps  │ ⚪ Backlog
        │               │              │
Impact  │               │              │
Basse   │ 🟡 Si temps   │ ⚪ Backlog    │ ⚪ Backlog
```

---

## ✅ Checklist d'Analyse par Parcours

### **Pour chaque parcours, vérifier** :

#### **Navigation & Structure**
- [ ] Navigation principale claire et accessible
- [ ] Breadcrumbs présents (si nécessaire)
- [ ] Liens de retour/fin de parcours logiques
- [ ] Menu mobile fonctionnel

#### **Formulaires**
- [ ] Labels clairs et explicites
- [ ] Champs obligatoires clairement indiqués
- [ ] Validation en temps réel (si applicable)
- [ ] Messages d'erreur clairs et actionnables
- [ ] Aide contextuelle pour champs complexes
- [ ] Sauvegarde automatique (si formulaire long)

#### **Feedback & Confirmation**
- [ ] Messages de succès clairs et visibles
- [ ] Messages d'erreur informatifs
- [ ] Indicateurs de chargement (spinners, progress bars)
- [ ] Confirmations avant actions destructives
- [ ] Notifications (toast, alertes) non intrusives

#### **Accessibilité**
- [ ] Navigation clavier complète (Tab, Enter, Esc)
- [ ] ARIA labels sur boutons et formulaires
- [ ] Contraste de couleurs suffisant (WCAG AA)
- [ ] Focus states visibles
- [ ] Screen reader compatible

#### **Mobile & Responsive**
- [ ] Interface adaptée aux petits écrans
- [ ] Boutons et zones cliquables suffisamment grandes
- [ ] Formulaires optimisés mobile
- [ ] Images responsives
- [ ] Performance mobile acceptable

#### **Performance**
- [ ] Temps de chargement acceptable (< 2s)
- [ ] Images optimisées (lazy loading si nécessaire)
- [ ] Pas de N+1 queries
- [ ] Cache utilisé efficacement

---

## 🎯 Améliorations Identifiées (À Compléter)

### **Priorité 1 : Quick Wins (Impact Haut, Effort Faible)**

- [ ] À documenter après analyse

### **Priorité 2 : Améliorations Importantes (Impact Haut, Effort Moyen)**

- [ ] À documenter après analyse

### **Priorité 3 : Améliorations Futures (Impact Moyen/Bas)**

- [ ] À documenter après analyse

---

## 📝 Notes d'Analyse

### **Méthodologie d'Analyse**

1. **Parcours réels** : Tester chaque parcours en conditions réelles
2. **Heuristiques UX** : Appliquer les 10 heuristiques de Nielsen
3. **Tests utilisateurs** : Si possible, observer des utilisateurs réels
4. **Analytics** : Analyser les données d'utilisation (si disponibles)
5. **Accessibilité** : Utiliser des outils d'audit (axe-core, WAVE)

### **Outils Recommandés**

- **Navigation** : Tester avec clavier uniquement
- **Accessibilité** : axe DevTools, WAVE, Lighthouse
- **Performance** : Lighthouse, WebPageTest
- **Mobile** : Chrome DevTools Device Mode, test sur vrais appareils

---

## 🔄 Prochaines Étapes

1. **Phase 1 : Analyse** (En cours)
   - [ ] Parcourir chaque parcours utilisateur
   - [ ] Documenter les points de friction
   - [ ] Identifier les améliorations possibles

2. **Phase 2 : Priorisation**
   - [ ] Classer les améliorations par impact/effort
   - [ ] Sélectionner les quick wins
   - [ ] Planifier les améliorations importantes

3. **Phase 3 : Implémentation**
   - [ ] Créer des issues/tâches pour chaque amélioration
   - [ ] Implémenter les quick wins en premier
   - [ ] Tester les améliorations

4. **Phase 4 : Validation**
   - [ ] Tester les parcours améliorés
   - [ ] Valider avec utilisateurs réels (si possible)
   - [ ] Documenter les résultats

---

## 📚 Références

- **Heuristiques UX** : [10 Usability Heuristics for User Interface Design (Nielsen)](https://www.nngroup.com/articles/ten-usability-heuristics/)
- **Accessibilité** : [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- **Shape Up** : Méthodologie adaptée pour ce projet

---

**Document créé le** : 2025-11-14  
**Dernière mise à jour** : 2025-11-14  
**Version** : 1.0

