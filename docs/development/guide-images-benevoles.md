# Tutoriel images bénévoles (site + réseaux)

## Page publique

- **Guide détaillé (site)** : `/guide-images` — ouvre le tutoriel avec la **fiche visuelle** (référence rapide) et les rappels.
- **Fichier SVG** (téléchargeable, imprimable) : `/guides/image-upload-reference.svg` — même contenu que la grande illustration de la page.

## Règle simple

- Le site accepte plusieurs **ratios** : **16:9** (paysage) et **4:5** (portrait type réseaux) sont les plus adaptés ; d’autres formats passent aussi (recadrage automatique).
- Garder le sujet et les éléments importants au **centre**.
- Éviter le texte collé aux bords (safe zone).

## Ce que fait le site

- Cartes / listings / boutique : recadrage **square 1:1**.
- Hero événement + carrousel annonces : recadrage **banner 16:9**.

## Réseaux sociaux

- Feed Instagram : 4:5 ou 1:1.
- Story / Reel : 9:16.
- Facebook / partage : le réseau peut recadrer autour de ~1.91:1 même si l’UI du site est en 16:9.

## Conseils pratiques

- Utiliser des visuels contrastés et lisibles.
- Limiter le texte intégré à l’image.
- Tester rapidement l’image sur mobile avant publication.

## Bonnes pratiques UX (rappel)

Aligné avec les usages courants des formulaires d’upload (voir aussi la page `/guide-images`) :

- **Consignes** visibles avant l’envoi : formats, taille max, ratios possibles.
- **Prévisualisation** quand le formulaire la propose.
- **Messages d’erreur** explicites si le fichier est refusé (type, poids).
- **Remplacement** de fichier clair sans perdre le contexte.

## Référence technique

Pour les détails de variantes et la matrice officielle :
[`../04-rails/setup/image-formats-and-variants.md`](../04-rails/setup/image-formats-and-variants.md)
