# Module Réseau Social – Plan Grenoble Roller

**Dernière mise à jour** : 2026-02-17  
**Contexte** : Mini réseau social (posts, profils, timeline) intégré à Grenoble Roller Rails 8, PWA installable.

---

## 1. Vue d’ensemble

**Choix validé** : **Option B + Option C**

- **Grenoble Roller (prod)** : **Full Rails 8 natif** (Hotwire, Turbo, Stimulus) — stack unifiée, PWA et service worker fournis par Rails 8.
- **Formation THP** : Exercice React + Jotai dans un **repo séparé** ; production reste full Rails.

Fonctionnalités cibles : auth, profils, posts (texte + photos), commentaires, lien post ↔ événement, PWA avec compteurs d’installation (Stimulus + localStorage).

---

## 2. État actuel du projet

| Élément | État | Impact |
|---------|------|--------|
| **Auth** | Devise | Conservé |
| **User** | first_name, last_name, bio, avatar (Active Storage), role | Profil existant |
| **Post** | ❌ Absent | À créer |
| **Route** | Modèle existant (parcours) | `route_id` sur Post = Phase 2+ si besoin |
| **Front** | Turbo, Stimulus, importmap, Propshaft | Stack actuelle |
| **PWA** | Fichiers `app/views/pwa/` présents, **routes commentées** | Activer routes + manifest + lien layout |
| **HTTPS** | Production Caddy + Let’s Encrypt | OK |

**Référence** : [docs/04-rails/pwa/conformite-2026.md](../04-rails/pwa/conformite-2026.md)

---

## 3. PWA – Mise en œuvre

### 3.1 Activation

1. **Routes** : décommenter `manifest` et `service-worker` dans `config/routes.rb`.
2. **Manifest** : adapter `app/views/pwa/manifest.json.erb` — `name`, `short_name`, `start_url`, `display: "standalone"`, icônes 192×192 et 512×512.
3. **Layout** : ajouter `<link rel="manifest" href="...">` et `<meta name="theme-color" ...>`.
4. **Service worker** : enregistrer dans `app/javascript/application.js` :
   ```js
   if ('serviceWorker' in navigator) {
     navigator.serviceWorker.register('/service-worker.js').catch(console.error);
   }
   ```
5. **Tests** : Lighthouse (Chrome DevTools) — audit PWA, installabilité, éventuellement offline.

### 3.2 Compteurs d’installation (Stimulus)

Logique "3 pages puis toutes les 2" ou "tous les 4 posts" : Stimulus controller(s) + `localStorage`. Les contrôleurs Stimulus sont branchés sur le DOM mis à jour par Turbo pour rester dans le pattern Hotwire.

---

## 4. Fonctionnalités (Rails natif)

Tout en **ERB, Turbo Frames, Turbo Streams, Stimulus, Active Storage**.

### Photos et médias

- 1 à 4 images par post (`has_many_attached :images` sur Post).
- Photos de spot, photos d’événement, carousel (Phase 3).

### Commentaires

- Modèle `Comment` (post_id, user_id, body, parent_id pour réponses en Phase 3).

### Partage d’événements

- `Post` avec `event_id` (belongs_to :event) optionnel.
- Carte d’événement, bouton "S'inscrire" dans le feed.

### Hotwire / UX

- Formulaires de posts en **Turbo Frames**.
- Mise à jour du feed : **redirect + flash** en Phase 1 ; **Turbo Streams** (append/prepend) en Phase 2.
- Pour broadcast temps réel (nouveaux posts) : `turbo_stream_from` + ActionCable.

---

## 5. Phasage et MVP

### Phase 1 – MVP de base

- Auth (Devise)
- Posts texte + 1 à 4 photos (Active Storage)
- Page feed : timeline triée par date, pagination (Pagy)
- Profil utilisateur : voir / éditer
- PWA installable (manifest + routes + registration dans application.js)
- Lien post ↔ événement (event_id)
- **Création de post** : redirect + flash (pas encore Turbo Streams)

### Phase 2 – Social enrichi

- **Turbo Streams** (nouveau post en temps réel)
- Commentaires simples (1 niveau)
- Carte d’événement dans le post
- Bouton "S'inscrire" depuis le feed
- Compteurs PWA (Stimulus + localStorage)

### Phase 3 – Avancé

- Réponses aux commentaires (parent_id)
- Réactions (likes)
- Carousel de photos
- Notifications (Action Mailer / Action Notifier)
- Filtres (spot, événement)
- `route_id` sur Post si besoin (modèle Route existant)

### Hors scope v1

- DM (messages privés)
- Offline avancé (cache service worker complexe)

---

## 6. Schéma de données

```
Post
├── user_id (belongs_to :user)
├── body (text, max ~500 chars)
├── event_id (optionnel, belongs_to :event)
├── route_id (optionnel, Phase 2+ — belongs_to :route)
├── visibility (string: public ; enum plus tard si followers/private)
├── created_at, updated_at
└── has_many_attached :images

Comment
├── post_id, user_id, body
├── parent_id (optionnel, Phase 3)
└── created_at, updated_at

Reaction (phase 3)
├── user_id, reactable_type, reactable_id
├── kind ("like", "love")
└── created_at
```

---

## 7. Prochaines étapes

1. Modèle `Post` + migration.
2. `PostsController` (index, create, destroy) + vues ERB.
3. `has_many_attached :images` sur Post.
4. PWA : activer routes, manifest, registration SW, lien layout.
5. Modèle `Comment` (Phase 2).
6. Turbo Streams + ActionCable (Phase 2).

---

## 8. Option A (référence, non retenue)

Monorepo Rails 8 + React + Jotai : réalisable via JS bundling (esbuild ou Vite) sans forcément casser importmap — bascule progressive possible. Pertinent pour formation THP ou front plus riche (maps, édition live). Non retenu pour Grenoble Roller prod.

---

## 9. Ressources

- [Rails 8 + PWA](https://guides.rubyonrails.org/) – manifest + service worker
- [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) – mises à jour temps réel
- [Active Storage](https://guides.rubyonrails.org/active_storage_overview.html) – images
- [docs/04-rails/pwa/conformite-2026.md](../04-rails/pwa/conformite-2026.md) – état PWA Grenoble Roller
