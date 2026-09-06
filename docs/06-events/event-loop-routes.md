---
title: "Boucles Multiples d'Événements (EventLoopRoute) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["event-loop-route", "events", "routes", "multi-loop"]
---

# Boucles Multiples d'Événements (EventLoopRoute)

**Dernière mise à jour** : 2025-01-30

Ce document décrit le système permettant d'associer plusieurs boucles (loops) à un événement, chacune avec sa propre route et distance.

---

## 📋 Vue d'Ensemble

Le système `EventLoopRoute` permet à un événement d'avoir plusieurs boucles, par exemple :
- **Boucle 1** : 5 km (parcours court)
- **Boucle 2** : 10 km (parcours moyen)
- **Boucle 3** : 15 km (parcours long)

Chaque boucle peut utiliser une route différente ou la même route avec une distance différente.

### Cas d'Usage

- **Randonnées avec plusieurs parcours** : Permettre aux participants de choisir leur distance
- **Parcours progressifs** : Boucle 1 courte, boucle 2 plus longue, etc.
- **Flexibilité** : Support à la fois parcours unique (rétrocompatibilité) et multi-boucles

---

## 🏗️ Modèle : `EventLoopRoute`

**Fichier** : `app/models/event_loop_route.rb`

### Attributs

| Attribut | Type | Description |
|----------|------|-------------|
| `event_id` | bigint | Événement concerné |
| `route_id` | bigint | Route associée (parcours prédéfini) |
| `loop_number` | integer | Numéro de la boucle (1, 2, 3, ...) |
| `distance_km` | decimal | Distance de la boucle en km (>= 0.1) |

### Relations

- `belongs_to :event`
- `belongs_to :route`

### Validations

- `loop_number` : présence, entier > 0, unicité scope `event_id`
- `distance_km` : présence, >= 0.1

### Index

- `[event_id, loop_number]` : Unique (un événement ne peut avoir qu'une seule boucle #X)
- `event_id` : Index pour performance
- `route_id` : Index pour performance

### Ransack (ActiveAdmin)

- Attributs recherchables : id, event_id, route_id, loop_number, distance_km, dates
- Associations recherchables : event, route

---

## 🔗 Intégration avec Event

### Relations Event

```ruby
class Event < ApplicationRecord
  belongs_to :route, optional: true  # Parcours principal (rétrocompatibilité)
  has_many :event_loop_routes, dependent: :destroy
  has_many :loop_routes, through: :event_loop_routes, source: :route
end
```

### Calcul de Distance Totale

**Méthode** : `total_distance_km`

```ruby
def total_distance_km
  # Si on utilise le nouveau système avec event_loop_routes
  if event_loop_routes.any?
    event_loop_routes.sum(:distance_km)
  else
    # Rétrocompatibilité : utiliser route principale
    route&.distance_km || distance_km || 0
  end
end
```

**Logique** :
- Si `event_loop_routes` existe → Somme des distances de toutes les boucles
- Sinon → Utilise `route.distance_km` ou `distance_km` (rétrocompatibilité)

### Affichage des Boucles

**Méthode** : `loop_routes_for_display`

```ruby
def loop_routes_for_display
  if event_loop_routes.any?
    # Charger les boucles depuis event_loop_routes
    event_loop_routes.order(:loop_number).each do |elr|
      {
        loop_number: elr.loop_number,
        route_name: elr.route.name,
        distance_km: elr.distance_km
      }
    end
  else
    # Rétrocompatibilité : utiliser route principale comme boucle 1
    if route
      [{ loop_number: 1, route_name: route.name, distance_km: route.distance_km }]
    end
  end
end
```

---

## 🛣️ Route API : `GET /events/:id/loop_routes`

### Endpoint

```
GET /events/:id/loop_routes.json
```

### Réponse JSON

```json
[
  {
    "loop_number": 2,
    "route_id": 5,
    "route_name": "Boucle longue",
    "distance_km": "15.0"
  },
  {
    "loop_number": 3,
    "route_id": 6,
    "route_name": "Boucle très longue",
    "distance_km": "20.0"
  }
]
```

**Note** : Ne retourne que les boucles `loop_number > 1` (la boucle 1 est le parcours principal).

### Utilisation

**Frontend JavaScript** : `app/javascript/controllers/event_form_controller.js`

```javascript
const response = await fetch(`/events/${eventId}/loop_routes.json`)
const loopRoutes = await response.json()
// Afficher les boucles dans le formulaire
```

---

## 📝 Formulaire de Création/Édition

### Paramètres Acceptés

```ruby
event_loop_routes: {
  "2" => { route_id: 5, distance_km: 15.0 },
  "3" => { route_id: 6, distance_km: 20.0 }
}
```

**Clé** : Numéro de boucle (string)  
**Valeur** : Hash avec `route_id` et `distance_km`

### Méthode : `save_loop_routes`

**Fichier** : `app/controllers/events_controller.rb`

```ruby
def save_loop_routes(event, loop_routes_params)
  # Supprimer toutes les boucles existantes
  event.event_loop_routes.destroy_all
  
  # Créer les nouvelles boucles
  loop_routes_params.each do |loop_number_str, route_data|
    next if route_data[:route_id].blank?
    
    event.event_loop_routes.create!(
      loop_number: loop_number_str.to_i,
      route_id: route_data[:route_id],
      distance_km: route_data[:distance_km]
    )
  end
end
```

**Logique** :
1. Supprimer toutes les boucles existantes
2. Créer les nouvelles boucles depuis les paramètres
3. Ignorer les entrées avec `route_id` vide

### JavaScript : Gestion Dynamique

**Fichier** : `app/javascript/controllers/event_form_controller.js`

**Fonctionnalités** :
- Ajout dynamique de nouvelles boucles
- Suppression de boucles
- Chargement des boucles existantes depuis l'API
- Validation des distances

---

## 🎯 Workflow

### Création Événement avec Multi-Boucles

1. **Parcours principal** : Sélectionner `route` (boucle 1, rétrocompatibilité)
2. **Boucles supplémentaires** : Cliquer "Ajouter une boucle"
3. **Sélectionner route** : Choisir une route pour chaque boucle
4. **Définir distance** : Entrer la distance en km
5. **Sauvegarder** : Les boucles sont créées via `save_loop_routes`

### Affichage dans la Vue

**Page événement** (`events/show.html.erb`) :
- Afficher toutes les boucles avec leurs distances
- Permettre de choisir la boucle souhaitée (futur)

---

## 🔄 Rétrocompatibilité

### Parcours Unique (Ancien Système)

Les événements existants avec un seul parcours continuent de fonctionner :

- `event.route` : Parcours principal
- `event.distance_km` : Distance principale
- Pas de `event_loop_routes` → Utilisation du parcours principal

### Migration Progressive

Les nouveaux événements peuvent utiliser le système multi-boucles, tandis que les anciens continuent avec le système unique.

---

## 📊 Exemples

### Exemple 1 : Randonnée avec 3 Parcours

```
Événement : "Rando vendredi soir"

Boucle 1 : Route "Centre-ville" - 5 km (parcours court)
Boucle 2 : Route "Ville + périphérie" - 10 km (parcours moyen)
Boucle 3 : Route "Grande boucle" - 15 km (parcours long)

Distance totale affichée : 30 km (somme des 3)
```

### Exemple 2 : Parcours Unique (Rétrocompatibilité)

```
Événement : "Rando simple"

Route principale : "Circuit classique" - 8 km
Pas de boucles supplémentaires

Distance totale affichée : 8 km (route principale)
```

---

## ⚠️ Limitations Actuelles

### Pas de Sélection de Boucle par Participant

- Les participants ne peuvent pas choisir leur boucle lors de l'inscription
- Tous les participants suivent le même parcours total
- Le système multi-boucles est principalement informatif

**Amélioration future possible** : Permettre aux participants de choisir leur boucle lors de l'inscription.

### Pas de Suivi par Boucle

- Pas de compteur d'inscriptions par boucle
- Pas de limite de participants par boucle
- Pas de statistiques par boucle

---

## 🔗 Références

- **Modèle** : `app/models/event_loop_route.rb`
- **Modèle Event** : `app/models/event.rb` (méthodes `total_distance_km`, `loop_routes_for_display`)
- **Contrôleur** : `app/controllers/events_controller.rb` (méthode `loop_routes`, `save_loop_routes`)
- **JavaScript** : `app/javascript/controllers/event_form_controller.js`
- **Route** : `GET /events/:id/loop_routes.json`
- **Migration** : `db/migrate/20251211150329_create_event_loop_routes.rb`

---

## 🎯 Améliorations Futures Possibles

1. **Sélection de boucle** : Permettre aux participants de choisir leur boucle
2. **Compteurs par boucle** : Suivre les inscriptions par boucle
3. **Limites par boucle** : Limiter le nombre de participants par boucle
4. **Affichage différencié** : Afficher les différentes boucles sur la carte
5. **GPX par boucle** : Générer des fichiers GPX séparés pour chaque boucle

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

