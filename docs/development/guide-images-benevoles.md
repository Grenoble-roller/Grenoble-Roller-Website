# Tutoriel images bénévoles (site + réseaux)

## Page publique

- **Guide détaillé (site)** : `/guide-images` — ouvre le tutoriel avec la **fiche visuelle** (référence rapide) et les rappels.
- **Fichier SVG** (téléchargeable, imprimable) : `/guides/image-upload-reference.svg` — même contenu que la grande illustration de la page.

---

## Règle simple

> **Format unique : 16:9 centré** sur toutes les surfaces du site (décision mai 2026).

- Garder le sujet et les éléments importants au **centre** (safe zone).
- Éviter le texte collé aux bords.
- Le site recadre automatiquement : une image 4:5 ou autre ratio fonctionne, le centre sera conservé.

---

## Ce que fait le site

| Surface | Rendu |
|---------|-------|
| Événements / initiations — cartes et listes | **16:9** (`cover`, centré) |
| Événements / initiations — page de détail (hero) | **16:9** (`cover`, centré) |
| Carrousel d'accueil | **16:9** (`cover`, centré) |
| Boutique — grille et fiche produit | **16:9** (`cover`, centré) |

---

## Réseaux sociaux

Les réseaux ont leurs propres contraintes, indépendantes du site :

- Feed Instagram : 4:5 ou 1:1.
- Story / Reel : 9:16.
- Facebook / partage : le réseau peut recadrer autour de ~1.91:1 même si l'UI du site est en 16:9.

---

## Conseils pratiques

- Utiliser des visuels contrastés et lisibles.
- Limiter le texte intégré à l'image.
- Tester rapidement l'image sur mobile avant publication.
- La **prévisualisation 16:9** dans le formulaire d'upload montre exactement le rendu final sur le site.

---

## Bonnes pratiques UX (rappel)

- **Consignes** visibles avant l'envoi : formats, taille max, ratio recommandé (16:9).
- **Prévisualisation** : le formulaire affiche le master (fichier entier) + le rendu 16:9 simulé.
- **Messages d'erreur** explicites si le fichier est refusé (type, poids).
- **Remplacement** de fichier clair sans perdre le contexte.

---

## Référence technique

Pour les détails de variantes et la matrice officielle :
[`../04-rails/setup/image-formats-and-variants.md`](../04-rails/setup/image-formats-and-variants.md)
