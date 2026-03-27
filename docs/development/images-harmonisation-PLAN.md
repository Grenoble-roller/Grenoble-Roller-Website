---
name: Harmonisation formats images
overview: Vocabulaire canonique (master/square/banner/story) ; upload unique master 4:5 ; rendu site via variants square+banner ; matrice surfaces figée ; preview admin généralisée (pattern carrousel) ; livraison WebP avec master préservé ; migration image_url en 3 phases avec critères de sortie ; story 9:16 = doc V1, variant serveur gate Phase B.
todos:
  - id: audit-image-usage
    content: Cartographier usages Event/Initiation/Carousel/Product/Variant, code paths preview, fallback image_url.
    status: pending
  - id: refactor-event-variants
    content: API variants square (1:1) + banner (16:9) ; alias rétrocompat uniquement si nécessaires (pas multiplier les noms).
    status: pending
  - id: refactor-shop-variants
    content: square pour grille + détail par défaut ; pipeline Active Storage ; pas de 4:5 sauf opt-in éditorial futur explicite.
    status: pending
  - id: preview-admin-pattern
    content: Généraliser double preview (contain master + cover par surface) events/boutique ; Stimulus partagé ou réplication contrôlée.
    status: pending
  - id: webp-delivery-strategy
    content: Standard livraison WebP (variants/format) sans perte du blob master en storage ; doc + vérif config ImageProcessing.
    status: pending
  - id: update-forms-guidelines
    content: Cohérence textes admin (upload = master ; rendu = square/banner) + safe zone ; vocabulare canonique dans les hints.
    status: pending
  - id: legacy-image-url
    content: Phase 1 masquer image_url UI → Phase 2 backfill/migration → Phase 3 suppression fallback ; critères de fin documentés.
    status: pending
  - id: refresh-documentation
    content: Doc pivot unique + satellites courts (liens depuis pivot uniquement pour ratios/noms) ; pas de tables dupliquées contradictoires.
    status: pending
  - id: align-carousel-form-copy-preview
    content: Copy carrousel alignée master + banner ; lien vers stratégie preview globale.
    status: pending
  - id: verify-and-test
    content: QA surfaces matrice + preview admin + absence régression image_url phases + specs/lints.
    status: pending
isProject: false
---

# Harmonisation images — Events, Carrousel, Boutique

Ce plan sépare explicitement trois axes pour éviter les ambiguïtés : **(A) politique de formats et vocabulaire**, **(B) comportement UI et preview**, **(C) stratégie de migration legacy**.

---

## A) Politique de formats — vocabulaire canonique

Noms **uniques** dans le code, les docs et l’admin (éviter de mélanger « hero », « card », « thumb », « cover » comme concepts produits ; les réserver aux **alias de compat** si besoin).


| Terme canonique | Ratio    | Rôle                                                                                               |
| --------------- | -------- | -------------------------------------------------------------------------------------------------- |
| **master**      | **4:5**  | **Seule source d’upload** bénévole / prod éditoriale (fichier original conservé en storage).       |
| **square**      | **1:1**  | Dérivé site : cartes, listes, **grille boutique**, **détail boutique par défaut**.                 |
| **banner**      | **16:9** | Dérivé site : **hero événement**, **carrousel homepage**, surfaces larges du **site**.             |
| **story**       | **9:16** | **Canal social / export** — voir section « Décision story » (V1 doc seulement vs variant serveur). |


### Source d’upload vs surface de rendu vs doc canal

- **Upload bénévole** = toujours **master 4:5** (une consigne).
- **Rendu site** = **square** et **banner** (variants / CSS alignés sur ces noms), jamais confondu avec « ce qu’on recommande sur Insta » dans le même paragraphe que le crop affiché.
- **Doc canal (hors UI)** = tableaux réseaux (Insta feed 4:5, Story 9:16, etc.) dans le **guide bénévoles** ou satellite ; le **pivot technique** renvoie à ce satellite pour les ratios « réseau », pas pour décrire le crop d’un composant Rails sans qualifier le contexte.

### Safe zone (prioritaire sur le ratio seul)

- Zone utile **large au centre** ; **texte jamais collé aux bords** ; **recadrage centré par défaut** (`object-position: center`, `resize_to_fill` centré).
- Les consignes admin et le guide bénévoles **mentionnent la safe zone avant les pixels exacts**.

### Facebook / Open Graph : 16:9 vs 1.91:1 — vocabulaire sans les fusionner

Ce ne sont **pas** le même ratio. Règle de rédaction :

- **Côté UI du site** : on documente et on implémente **banner = 16:9** (carrousel, hero event, etc.).
- **Côté canal Facebook / previews OG-like** : documenter que le **réseau peut recadrer ou attendre ~1.91:1** ; c’est une **tolérance / contrainte externe**, pas un troisième « ratio produit » au même niveau que banner. Formulation type : « UI site en 16:9 ; tolérance FB / partage ~1.91:1 hors site ».

---

## B) Matrice surfaces (figée — règle nette boutique)


| Surface                          | Rendu site            | Variant / note                                                                                                             |
| -------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Event card / liste               | **square**            | 1:1                                                                                                                        |
| Event hero / bandeau event       | **banner**            | 16:9                                                                                                                       |
| Carousel homepage                | **banner**            | 16:9 (existant 1200×675)                                                                                                   |
| Boutique grille (listing)        | **square**            | 1:1                                                                                                                        |
| Boutique fiche produit           | **square** par défaut | 1:1 — **pas de zone grise**                                                                                                |
| Boutique fiche « éditorial 4:5 » | **opt-in futur**      | 4:5 **uniquement** si produit/marketing décide un bloc dédié plus tard ; **hors scope** tant qu’aucune maquette ne l’exige |
| Story (export / social)          | **story**             | V1 = doc / export manuel ; V2 = variant serveur si Phase B validée                                                         |


**Reco nette réaffirmée** : master 4:5 unique ; **square** partout listings + **détail boutique** ; **banner** carrousel + hero event ; **story** tranché comme ci-dessous.

---

## C) Décision **story** (9:16) — fin de l’ambiguïté doc / code

- **Implémentation initiale (V1)** : **story** = **documentation + guide bénévoles** (export Canva / fichier manuel). **Pas** de variant Active Storage obligatoire nommé `story`, **pas** de promesse « généré sur le site » dans le pivot.
- **Phase B (optionnelle)** : variant serveur `story` (`resize_to_fill` 9:16, usage téléchargement ou intégration) **uniquement** après validation explicite (stockage, jobs, besoin métier) — **ADR ou mini-ADR** dans `docs/adr/` si on active la génération.

---

## D) Comportement UI — stratégie de preview (renforcer le plan)

Le plan historique parlait surtout de **variants** ; il manquait l’**expérience bénévole** entre upload et rendu.

### Pattern de référence (carrousel — déjà en place)

- **Preview 1 — master** : `object-fit: contain` (voir le fichier entier sans crop).
- **Preview 2 — rendu cible** : cadre **banner** verrouillé (`aspect-ratio: 16/9`), `cover` + centre ; si fichier déjà persisté → **variant serveur** identique à la prod ; si fichier local → blob + **approximation** CSS jusqu’au save.

### À généraliser

- **Events / initiations** : même logique — **contain** + **square** (1:1) pour carte, **banner** (16:9) pour hero si le formulaire couvre les deux usages (ou onglets / deux cadres).
- **Boutique (admin)** : **contain** + **square** pour le rendu grille/détail par défaut.
- **Livrable technique** : Stimulus **réutilisable** (ex. `media-preview`) paramétré par ratios cibles, **ou** réplication documentée avec checklist — pour éviter les surprises « mon image ne ressemble pas à la liste ».

### Format de sortie côté site (livraison)

- **Upload accepté** : JPG / PNG / WebP (rester permissif à l’entrée).
- **Standard de livraison** : privilégier **WebP** dans les variants servis aux navigateurs compatibles (configuration ImageProcessing / représentations Rails selon stack actuelle — à préciser en exécution sans casser les clients anciens).
- **Master** : **conserver l’original** en storage (pas de remplacement du blob source par le seul WebP).

---

## E) Migration `image_url` — critères de sortie (plus de doublon permanent)

Trois phases avec **jalon de fin** :

1. **Phase 1 — UI** : plus aucune **création / édition** n’expose `image_url` (forms admin + ActiveAdmin + seeds doc) ; chemins résiduels documentés comme lecture seule si nécessaire pour urgence.
2. **Phase 2 — données** : **backfill** ou migration : pour chaque enregistrement encore dépendant d’une URL, attacher le fichier ou marquer « à traiter » avec rapport ; critère : **inventaire à zéro ou liste fermée** avec propriétaire.
3. **Phase 3 — code** : suppression du **fallback** `image_url` dans helpers/vues ; suppression ou garde-fou colonne selon stratégie DB (soft-deprecation puis drop migration si applicable).

**Critère de fin du projet migration** : « **Aucune branche d’affichage ne lit `image_url` pour le rendu produit** » + tests de non-régression sur produits sans pièce jointe (comportement défini : placeholder, masquage, etc.).

---

## Constat actuel (audit — inchangé côté code)

- **Carrousel** : banner 16:9, `resize_to_fill` 1200×675, CSS cohérent — `[app/views/pages/_announcement_banner.html.erb](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/views/pages/_announcement_banner.html.erb)`, `[docs/development/homepage-carousel.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/development/homepage-carousel.md)`.
- **Events** : variants historiques + consignes contradictoires — `[app/models/event.rb](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/models/event.rb)`, formulaires / ActiveAdmin.
- **Boutique** : Active Storage + fallback `image_url` — `[app/models/product.rb](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/models/product.rb)`, `[app/helpers/products_helper.rb](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/helpers/products_helper.rb)`, vues index/show.

---

## Référence vérifiée : carrousel (upload, preview admin, verrouillage CSS)

Pattern validé pour les surfaces **banner** — voir fichiers `[_form.html.erb` admin carrousel](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/views/admin_panel/homepage_carousels/_form.html.erb), `[carousel_form_controller.js](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/javascript/controllers/carousel_form_controller.js)`, `[_announcement_banner.html.erb](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/views/pages/_announcement_banner.html.erb)`, `[_style.scss](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/app/assets/stylesheets/_style.scss)` (`#announcementCarousel` : `aspect-ratio: 16/9`, cover centré).

---

## Documentation — pivot + satellites (éviter les contradictions)

**Pivot unique** : `[docs/04-rails/setup/image-formats-and-variants.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/setup/image-formats-and-variants.md)` — **seule** source pour : vocabulaire canonique, matrice surfaces, preview, phases `image_url`, décision story V1/V2, renvoi WebP/master.

**Satellites courts** (sans dupliquer la matrice complète) :

- `[active-storage-image-optimization.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/setup/active-storage-image-optimization.md)` : détails techniques events **ou** lien « détails dans le pivot ».
- `[homepage-carousel.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/development/homepage-carousel.md)` : fichiers, comportement feature, lien pivot.
- `[active-storage-minio-setup.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/setup/active-storage-minio-setup.md)` : infra.
- Optionnel FR : `[docs/development/guide-images-benevoles.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/development/guide-images-benevoles.md)` — **doc canal** + safe zone ; pas de nouvelle « vérité » technique qui contredirait le pivot.
- `[docs/04-rails/setup/README.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/setup/README.md)` : lien vers le pivot en tête « Images ».

Règle : **toute modification de ratio ou de nom canonique** → éditer le **pivot** d’abord, puis ajuster les satellites en **lien** uniquement si nécessaire.

---

## Plan d’implémentation (Plan → Execute → Verify)

### 1) Events / Initiations — `cover_image`

- Exposer des méthodes / variants nommés **square** et **banner** (1:1 et 16:9) alignés sur la matrice.
- **Alias** (`cover_image_hero`, etc.) : **uniquement** si la régression l’exige ; déprécier dans le code et documenter la table d’alias → canonique dans le pivot.
- Vues : liste → **square** ; hero → **banner** ; pas de **banner** sur les petites cards.

### 2) Carrousel (`HomepageCarousel`)

- Conserver **banner** 16:9 (rendu + CSS + `resize_to_fill` actuel).
- Textes : upload = **master** ; affichage = **banner** ; renvoi vers stratégie preview globale.

### 3) Boutique — `Product` / `ProductVariant`

- **square** pour grille et **détail par défaut** ; pipeline unique depuis master uploadé.
- **4:5 éditorial** : **hors scope** sauf nouvelle décision produit + maquette (pas de « on verra » dans les forms).
- `**image_url`** : suivre phases E avec critères de fin.

### 4) Preview admin + WebP

- Implémenter **preview admin** (pattern double cadre) pour events et boutique.
- Implémenter / documenter **WebP** comme sortie servie + **master préservé** (tâche dédiée `webp-delivery-strategy`).

### 5) Documentation

- Créer le **pivot** ; satellites = liens ; mettre à jour admin boutique (`[produits.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/admin-panel/01-boutique/produits.md)`, `[variantes.md](/home/flowtech/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project/docs/04-rails/admin-panel/01-boutique/variantes.md)`) : phases `image_url` + vocabulaire.

### 6) QA

- Vérifier chaque ligne de la **matrice surfaces** + previews admin + **phases migration** (pas de régression sur produits sans attachment après Phase 3).

---

## Risques et mitigation

- **Recadrage** ancien contenu : safe zone + recadrage centré + communication.
- `**image_url`** : inventaire avant Phase 3 ; pas de suppression fallback avant critère données.
- **story V2** : ne pas lancer sans ADR/coût stockage.

---

## Rollback / annulation

- Revert Git par lot ; migration `image_url` : garder une branche / export inventaire avant Phase 3.

---

## Estimation

- **Events + carrousel + pivot doc + preview events** : ~**2–3 jours**.
- **+ Boutique (variants square + preview + phases image_url)** : **+1.5–2.5 jours**.
- **+ WebP / représentations** : **+0.5–1 jour** selon état `image_processing`/config.
- **Buffer QA** : **+0.5 jour**.

