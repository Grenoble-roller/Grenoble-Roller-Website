# SEO Audit Report – grenoble-roller.org & staging.grenoble-roller.org

**Date**: 2026-09-16  
**Audit performed using**: Ahrefs (score 12/100) – data provided by user.

## Summary

Both the production (`grenoble-roller.org`) and staging (`staging.grenoble-roller.org`) sites share the same SEO shortcomings, as reflected in the identical audit output:

- **Overall SEO score**: 12/100 (very low)  
- **HTML size**: 36.5 KB (acceptable)  
- **Heading structure**: H1 = 1, H2 = 3, H3 = 5, H4‑H6 = 0  
- **Main content load**: reported as too slow  

The audit highlights missing or suboptimal elements in the following categories: **GEO** (local/search visibility), **SEO** (on‑page optimisation), **Technique** (performance & crawlability), **Métadonnées** (Open Graph / Twitter Card), and **Liens** (anchor text).

---

## Detailed Findings

| Category | Issue | Current Value | Recommendation | Estimated GEO/SEO impact |
|----------|-------|---------------|----------------|--------------------------|
| **GEO** | Pas de données structurées JSON‑LD | Aucun schéma détecté | Ajouter au moins un schéma JSON‑LD (ex. `Organization`, `LocalBusiness`, `FAQPage`, ou `Event`) | +6 points GEO |
| **GEO** | Peu de formats Q&R | Peu de formulations en forme de question | Intégrer des formulations du type « Comment », « Quoi », « Pourquoi » dans le contenu (FAQ, blocs d’aide) | Jusqu’à +3 points GEO |
| **GEO** | URL canonique manquante | Aucune balise `<link rel="canonical">` | Ajouter `<link rel="canonical" href="https://grenoble-roller.org/">` (ou l’URL absolue de chaque page) | +3 points GEO |
| **SEO** | Titre de page trop court | 15 caractères | Allonger le titre à 30‑60 caractères, incluant le nom du site et une phrase descriptive (ex. « Site officiel du Grenoble Roller – Boutique, événements, adhésions ») | Améliore le classement & CTR |
| **SEO** | Méta description trop longue | 206 caractères | Raccourcir à ≤ 160 caractères (ex. « Boutique en ligne, événements roller, adhésions HelloAsso pour le club de roller de Grenoble. Infos, inscriptions et boutique officielle. ») | Évite la troncature dans les SERP |
| **SEO** | Titre H1 hors contenu | Un titre utilisé comme libellé d’interface (pas du contenu réel) | Remplacer ou supprimer cette balise H1 ; s’assurer qu’il n’y ait qu’un seul H1 décrivant le sujet principal de la page | Évite la confusion pour les moteurs |
| **SEO** | Ancres génériques | 2 liens avec texte du type « cliquez ici » | Remplacer par des ancres descriptives (ex. « Voir les événements à venir », « Accéder à la boutique ») | Meilleur signal de pertinence |
| **Technique** | Chargement du contenu principal trop lent | – | Optimiser le critical rendering path : <br>• Minifier et compresser CSS/JS <br>• Utiliser le préchargement (`link rel=preload`) pour les polices et les images critiques <br>• Activer la compression Brotli/Gzip côté serveur <br>• Utiliser le lazy‑loading pour les images hors‑viewport <br>• Exploiter le cache du navigateur (en‑têtes `Cache-Control`) | Améliore LCP & expérience utilisateur |
| **Métadonnées** | Titre Open Graph manquant | Aucune balise `og:title` | Ajouter `<meta property="og:title" content="Titre de la page – Grenoble Roller">` | Meilleur affichage lorsqu’il est partagé |
| **Métadonnées** | Description Open Graph manquante | Aucune balise `og:description` | Ajouter `<meta property="og:description" content="Description courte de la page">` | Idem |
| **Métadonnées** | Image Open Graph manquante | Aucune balise `og:image` | Ajouter `<meta property="og:image" content="URL vers une image représentative (logo ou photo d’événement)">` | Augmente le taux de clic sur les réseaux |
| **Métadonnées** | Balise Twitter Card manquante | Aucune balise `twitter:card` | Ajouter `<meta name="twitter:card" content="summary_large_image">` (ou `summary`) + éventuellement `twitter:site`, `twitter:creator` | Optimise l’affichage sur Twitter/X |

## Prioritisation des actions

| Priorité | Action | Raison |
|----------|--------|--------|
| **Haute** | Ajouter des données structurées JSON‑LD (Organization/LocalBusiness) | Impact GEO +6, facile à implémenter via un partial ou un helper. |
| **Haute** | Corriger le titre et la méta description (longueur, contenu) | Influence directe sur le CTR dans les SERP, rapide. |
| **Haute** | Définir une URL canonique | Évite le contenu dupliqué, indispensable pour le SEO. |
| **Moyenne** | Remplacer les ancres génériques | Améliore la pertinence interne, faible effort. |
| **Moyenne** | Ajouter les balises Open Graph et Twitter Card | Améliore le partage sur les réseaux sociaux, bénéfice immédiat. |
| **Moyenne‑Faible** | Enrichir le contenu avec des formulations Q&R (FAQ) | Peut rapporter jusqu’à +3 GEO, nécessite rédaction de contenu. |
| **Faible** | Optimiser le temps de chargement (critical CSS, lazy‑load, compression) | Importante pour l’expérience utilisateur mais nécessite plus de travail technique ; à planifier dans le prochain sprint. |

## Implémentation suggérée (exemple de données structurées)

Dans le layout principal (`app/views/layouts/application.html.erb`) ou via un helper :

```erb
<%# JSON‑LD for Organization %>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Grenoble Roller",
  "url": "https://grenoble-roller.org/",
  "logo": "https://grenoble-roller.org/assets/images/logo.png",
  "sameAs": [
    "https://www.facebook.com/GrenobleRoller",
    "https://www.instagram.com/grenobleroller/",
    "https://twitter.com/grenobleroller"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+33-4-XX-XX-XX-XX",
    "contactType": "Customer service",
    "areaServed": "FR"
  }
}
</script>
```

Pour les pages d’événement, utiliser le type `Event` avec les propriétés `startDate`, `endDate`, `location`, `offers`, etc.

## Conclusion

Le site présente de nombreuses opportunités d’amélioration SEO assez simples à mettre en œuvre (données structurées, balises méta, canonique, ancres descriptives). Leur mise en place devrait permettre de remonter nettement le score Ahrefs bien au‑delà de 12/100, améliorer la visibilité locale (GEO) et augmenter le trafic qualifié provenant des moteurs de recherche et des réseaux sociaux.

--- 
*Ce rapport doit être conservé dans `docs/09-product/seo-audit.md` pour référence future et suivi des actions.*