# 📋 Récapitulatif - Ce qui reste à faire

**Date** : 2025-01-30  
**Statut** : Quick Wins 80% terminés (33/41)

---

## 🟢 QUICK WINS RESTANTS (8)

### **Parcours 7 : Achat en Boutique**
- [ ] Barre de recherche produits (AJAX) - **DÉPRIORISÉ** (peu de produits ~6-7)

**Note** : Tous les autres Quick Wins sont terminés ✅

---

## 🟡 AMÉLIORATIONS IMPORTANTES PRIORITAIRES

### **Parcours 1 : Découverte de l'Association**
- [ ] Newsletter fonctionnelle (Formulaire footer + backend avec service email)
- [ ] Page "Équipe" (Créer page statique manquante)
- **Note** : Section "Tarifs d'adhésion" et "Derniers événements" retirées - la page d'accueil fera l'objet d'une recherche dédiée plus tard

### **Parcours 2 : Inscription**
- [ ] Validation email en temps réel (Vérifier si email existe déjà via AJAX)
- [ ] Page de bienvenue après inscription (Redirection vers `/welcome` avec guide "Prochaines étapes")
- [ ] Indicateur de progression du formulaire (Barre "Étape 1/1" pour préparer futures étapes)

### **Parcours 3 : Découverte des Événements**
- [ ] Barre de recherche (Recherche par titre, description, lieu - AJAX)
- [ ] Filtres basiques (Filtres par date, route, niveau)
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Popularité, Distance, Nouveautés)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar - vue mensuelle)
- [ ] Filtres avancés (Filtres combinés avec tags actifs visibles)

### **Parcours 4 : Inscription à un Événement**
- [ ] Confirmation en deux étapes (Étape 1 modal → Étape 2 page de confirmation)
- [ ] Notification push (optionnel) (Demander permission pour notifications push)

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Filtres basiques (Filtres par date, statut rappel)
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar)
- [ ] Actions en masse (Checkbox pour sélectionner plusieurs événements et désinscription en masse)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Nom, Distance)
- [ ] Export calendrier global (Export iCal de toutes ses inscriptions en une fois)

### **Parcours 6 : Création d'un Événement**
- [ ] Formulaire en plusieurs étapes (Étape 1 Infos de base → Étape 2 Détails → Étape 3 Options)
- [ ] Prévisualisation événement (Bouton "Aperçu" qui montre la card événement)
- [ ] Création route depuis formulaire (Modal "Créer un nouveau parcours" directement)
- [ ] Duplication d'événement (Bouton "Dupliquer" sur événement existant)
- [ ] Templates d'événements (Templates pré-remplis : "Rando vendredi soir", etc.)
- [ ] Validation côté client (Validation HTML5 + JavaScript avant soumission)

### **Parcours 7 : Achat en Boutique**
- [ ] Tri des produits (Dropdown "Trier par" : Prix, Nom, Popularité)
- [ ] Galerie d'images (Carrousel avec plusieurs images par produit)
- [ ] Panier persistant pour utilisateurs connectés (Sauvegarder panier en DB, fusionner avec session)
- [ ] Sauvegarde panier avant déconnexion (Sauvegarder automatiquement le panier en DB)
- [ ] Récapitulatif avant paiement (Page intermédiaire "Récapitulatif" avec adresse de livraison)
- [ ] Suggestions produits ("Produits similaires" ou "Autres clients ont aussi acheté")

### **Parcours 8 : Administration**
- [ ] Bulk actions (Sélectionner plusieurs événements → "Publier en masse", "Refuser en masse")
- [ ] Recherche globale (Barre de recherche qui cherche dans Events, Users, Orders)
- [ ] Regroupement menu (Menu groupé : "Événements" → Events, Routes, Attendances)
- [ ] Exports avancés (Exports CSV personnalisés avec colonnes choisies, exports PDF)
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres fréquents)
- [ ] Dashboard complet avec graphiques (Graphiques : événements par mois, inscriptions, revenus)

### **Parcours 9 : Navigation via Footer**
- [ ] Page "Équipe" (Créer page statique manquante)
- [ ] Page "Carrières" (Si recrutement prévu : offres d'emploi)
- [ ] Page "Blog" (Si blog prévu, créer structure de base ou masquer le lien)

---

## 🔴 AMÉLIORATIONS FUTURES (Impact Moyen, Effort Élevé)

### **Parcours 1 : Découverte**
- [ ] Témoignages membres (Section avec 2-3 témoignages + photos)
- [ ] Galerie photos (Carrousel avec photos d'événements passés)
- [ ] Carte interactive (Carte avec points de départ des événements récurrents)

### **Parcours 2 : Inscription**
- [ ] Inscription en plusieurs étapes (Étape 1 identité → Étape 2 profil → Étape 3 préférences)
- [ ] Inscription via réseaux sociaux (OAuth : Google, Facebook)
- [ ] Vérification téléphone (SMS) (Optionnel pour sécurité renforcée)
- [ ] Onboarding interactif (Tour guidé de l'application après première connexion)

### **Parcours 3 : Découverte des Événements**
- [ ] Carte interactive (Carte avec points des événements, filtrage par zone géographique)
- [ ] Suggestions personnalisées ("Événements qui pourraient vous intéresser" basé sur historique)
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres favoris)

### **Parcours 4 : Inscription à un Événement**
- [ ] Inscription avec paiement (Si événement payant, intégrer le paiement dans le flux)
- [ ] Inscription groupée (Permettre d'inscrire plusieurs personnes en une fois)
- [ ] Liste d'attente (Si événement complet, proposer de s'inscrire sur liste d'attente)
- [ ] QR code de confirmation (Générer un QR code unique pour chaque inscription)

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Statistiques personnelles (Graphique "Nombre de sorties par mois", "Kilomètres parcourus")
- [ ] Historique complet (Voir toutes les sorties y compris annulées avec filtre par statut)
- [ ] Rappels personnalisés (Paramètres globaux pour rappels : toujours activer, désactiver)
- [ ] Partage de ses sorties (Lien public pour partager sa liste de sorties à venir)

### **Parcours 6 : Création d'un Événement**
- [ ] Éditeur WYSIWYG pour description (Éditeur riche : Trix, TinyMCE)
- [ ] Planification récurrente (Créer plusieurs événements à la fois : tous les vendredis du mois)
- [ ] Aide contextuelle avancée (Tooltips avec exemples concrets pour chaque champ)
- [ ] Historique de modifications (Voir l'historique des modifications d'un événement)

### **Parcours 7 : Achat en Boutique**
- [ ] Comparaison de produits (Permettre de comparer 2-3 produits côte à côte)
- [ ] Liste de souhaits (Wishlist) (Permettre d'ajouter des produits à une liste de souhaits)
- [ ] Avis clients (Système d'avis et notes sur les produits)
- [ ] Historique de navigation ("Produits récemment consultés")
- [ ] Notifications stock ("Me prévenir quand ce produit sera de nouveau en stock")
- [ ] Codes promo (Système de codes promotionnels)

### **Parcours 8 : Administration**
- [ ] Tableau de bord personnalisable (Admin peut choisir quels widgets afficher)
- [ ] Notifications admin (Alertes pour événements à valider, commandes en attente)
- [ ] Workflow de modération (Interface dédiée pour modérer avec commentaires)
- [ ] Rapports automatiques (Génération automatique de rapports par email)
- [ ] Audit trail visuel (Interface visuelle pour voir l'historique des modifications avec qui/quand)

### **Parcours 9 : Navigation via Footer**
- [ ] Système de blog complet (Si blog prévu : articles, catégories, commentaires)
- [ ] Page Carrières (Si recrutement prévu : offres d'emploi)
- [ ] Filtres "Catégories" et "Villes" (Si filtres événements prévus : pages dédiées)
- [ ] Newsletter avancée (Segmentation, templates, analytics)

---

## 📊 Statistiques

**Quick Wins** : 33/41 terminés (80%) - **8 restants** (1 dépriorisé)  
**Améliorations Importantes** : ~48 identifiées - **~30 prioritaires**  
**Améliorations Futures** : ~33 identifiées - À planifier selon besoins

---

## 🎯 Prochaines Actions Recommandées (Top 5)

1. **Newsletter fonctionnelle** (Parcours 1) - Impact haut, effort moyen
2. **Validation email en temps réel** (Parcours 2) - Impact haut, effort moyen
3. **Barre de recherche événements** (Parcours 3) - Impact haut, effort moyen
4. **Filtres basiques événements** (Parcours 3) - Impact haut, effort moyen
5. **Pagination événements** (Parcours 3) - Impact haut, effort moyen

---

**Document créé le** : 2025-01-30  
**Source** : [`ux-improvements-backlog.md`](ux-improvements-backlog.md)

