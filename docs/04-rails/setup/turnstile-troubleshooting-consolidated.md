---
title: "Turnstile - Dépannage et Tests Consolidés"
status: "active"
version: "2.1"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["turnstile", "troubleshooting", "testing", "debug"]
---

# Turnstile - Dépannage et Tests Consolidés

**Dernière mise à jour** : 2026-08-14  
**Document consolidé** : Fusion de 8 fichiers de dépannage et tests Turnstile

---

## 📋 Vue d'Ensemble

Ce document consolide toute la documentation de dépannage et de tests pour Cloudflare Turnstile. Pour la configuration initiale, voir [`turnstile-setup.md`](turnstile-setup.md).

---

## ✅ Comment Vérifier que Turnstile Fonctionne

### Mode Invisible = Rien de Visible !

**Important** : En mode invisible, Turnstile fonctionne complètement en arrière-plan. Aucun widget visible pour l'utilisateur.

### Méthode 1 : DevTools Navigateur (Recommandé)

**Étapes** :
1. Ouvrir la page de connexion/inscription
2. Ouvrir DevTools (F12 ou Cmd+Option+I)
3. Onglet **Network** :
   - Filtrer par `turnstile` ou `cloudflare`
   - Vérifier requête vers `challenges.cloudflare.com/turnstile/v0/api.js` (chargement script)
   - À la soumission : requête vers `/siteverify` (vérification)
4. Onglet **Console** :
   - Pas d'erreurs JavaScript
   - Si `turnstile` visible dans variables globales = OK

### Méthode 2 : Logs Rails

```bash
docker compose -f ops/dev/docker-compose.yml logs -f web | grep -i turnstile
```

**Ce que vous devriez voir** :
- Pas de logs Turnstile = Normal (si tout fonctionne)
- `Turnstile verification failed` = Échec (normal si clés incorrectes)
- `Turnstile verification error` = Erreur technique

### Méthode 3 : Vérifier les Clés

```bash
# Vérifier site_key
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "puts Rails.application.credentials.dig(:turnstile, :site_key) || 'CLÉ MANQUANTE'"

# Vérifier secret_key
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "puts Rails.application.credentials.dig(:turnstile, :secret_key).present? ? '✅ Secret Key OK' : '❌ Secret Key manquante'"
```

### Méthode 4 : Test Simple

**Sans clé Turnstile** : Le formulaire se soumet normalement (skip si clé manquante en dev)

**Avec clé Turnstile** : Le formulaire attend la vérification, message d'erreur si échec

### Méthode 5 : Vérifier Code Source HTML

Rechercher dans le code source :
```html
<div class="cf-turnstile" data-sitekey="...">
```
Si présent avec `site_key` valide = Widget bien chargé

---

## 🔍 Dépannage

### Problème : Widget ne se charge pas

**Symptômes** : Pas de requête vers Cloudflare dans Network tab

**Solutions** :
1. Vérifier que `turnstile_site_key` est présent dans credentials
2. Vérifier console JavaScript pour erreurs
3. Vérifier que le script Cloudflare est chargé (Network tab → chercher `api.js`)

### Problème : Vérification échoue toujours

**Symptômes** : Message "Vérification de sécurité échouée"

**Solutions** :
1. Vérifier que `TURNSTILE_SECRET_KEY` est configuré correctement
2. Vérifier les logs Rails :
   ```bash
   docker compose -f ops/dev/docker-compose.yml logs web | grep -i "turnstile\|verification"
   ```
3. Vérifier que le domaine est bien configuré dans Cloudflare Dashboard
4. Vérifier que les clés correspondent (site key et secret key du même site)

### Problème : Erreur 422 "Unprocessable Entity"

**Symptômes** : Le formulaire retourne 422, mais l'utilisateur peut quand même se connecter après refresh

**Cause** : Token Turnstile non généré au moment du submit, ou vérification échoue

**Solutions** :
1. Vérifier que le token est présent avant soumission (DevTools → Elements → chercher `<input name="cf-turnstile-response">`)
2. JavaScript désactive le bouton submit jusqu'à génération du token
3. Vérifier que `verify_turnstile` bloque bien avant `super` dans les contrôleurs

**Code attendu dans contrôleurs** :
```ruby
def create
  unless verify_turnstile
    render :new, status: :unprocessable_entity
    return false
  end
  super # Appel à Devise
end
```

### Problème : Erreurs 401 dans Console (Normales)

**Erreurs** :
```
GET https://challenges.cloudflare.com/cdn-cgi/challenge-platform/h/g/pat/... 401 (Unauthorized)
```

**Ces erreurs sont NORMALES** :
- Cloudflare fait des vérifications de sécurité en arrière-plan
- Les 401 sont des réponses normales aux challenges
- N'affecte PAS le fonctionnement de Turnstile
- Le token est toujours généré correctement

### Problème : Développement Local

**Pour tester en localhost** :
1. Ajouter `localhost` ou `127.0.0.1` dans domaines autorisés Cloudflare
2. OU utiliser clés de test Cloudflare :
   - Site Key : `1x00000000000000000000AA`
   - Secret Key : `1x0000000000000000000000000000000AA`
3. OU laisser vide (en dev, Turnstile skip si clé manquante)

---

## 🧪 Tests de Validation

### Test : Vérifier Blocage Authentification

**Scénario** : Tenter connexion SANS token Turnstile valide

**Étapes** :
1. Ouvrir onglet privé
2. Aller sur `/users/sign_in`
3. DevTools → Console, exécuter :
   ```javascript
   // Supprimer le token Turnstile (simuler échec)
   document.querySelector('input[name="cf-turnstile-response"]').remove();
   ```
4. Soumettre le formulaire
5. Vérifier : Erreur 422, utilisateur NON connecté

### Test : Suivre Logs Complets

```bash
# Suivre TOUS les logs (sans filtres)
docker compose -f ops/dev/docker-compose.yml logs -f web 2>&1
```

**Rechercher dans logs** :
- `🔵 SessionsController#create DEBUT`
- `🔴 Turnstile verification FAILED`
- `🟢 Turnstile verification PASSED`
- `Processing by SessionsController#create`

---

## 🛠️ Commandes de Debug

### Suivre Logs en Temps Réel

```bash
docker compose -f ops/dev/docker-compose.yml logs -f web
```

### Chercher Erreurs Turnstile

```bash
docker compose -f ops/dev/docker-compose.yml logs web --tail=500 | grep -i -A 10 -B 5 "turnstile\|422\|verification\|security\|failed"
```

### Chercher Requêtes POST

```bash
docker compose -f ops/dev/docker-compose.yml logs web --tail=500 | grep -i -A 20 "POST.*sign_in\|sessions#create"
```

### Voir Logs Rails Directement

```bash
docker compose -f ops/dev/docker-compose.yml exec web tail -100 log/development.log
```

### Filtrer avec Line Buffering

```bash
docker compose -f ops/dev/docker-compose.yml logs -f web 2>&1 | grep --line-buffered -i "turnstile\|422\|sign_in\|sessions\|verification\|failed"
```

---

## 📝 Notes Importantes

### Erreurs JavaScript Normales

Les erreurs suivantes sont **normales** et ne sont **pas** un problème :
- `GET ... 401 (Unauthorized)` sur challenges.cloudflare.com
- `No available adapters`
- `Note that 'script-src' was not explicitly set...`
- `Request for the Private Access Token challenge`

**Raison** : Liées aux fonctionnalités avancées de sécurité Cloudflare, n'affectent pas Turnstile.

### "Vous êtes déjà connecté"

Si vous voyez ce message en rafraîchissant la page de connexion, c'est normal : Devise redirige les utilisateurs déjà connectés.

**Pour tester** :
- Se déconnecter d'abord (`/users/sign_out`)
- OU utiliser un onglet privé
- OU modifier la session dans Rails console

### Mode Test

En environnement `test`, Turnstile est automatiquement désactivé (skip verification) pour permettre les tests automatisés.

---

## 🔗 Références

- **Configuration** : [`turnstile-setup.md`](turnstile-setup.md)
- **Cloudflare Turnstile** : https://developers.cloudflare.com/turnstile/

---

## 📚 Fichiers Consolidés

Ce document remplace les fichiers suivants (conservés pour référence mais consolidés ici) :
- `turnstile-test-verification.md`
- `turnstile-test-guide.md`
- `turnstile-test-simple.md`
- `turnstile-troubleshooting.md`
- `turnstile-debug-steps.md`
- `turnstile-debug-commands.md`
- `turnstile-errors-cloudflare.md`
- `turnstile-verification-problem.md`

---

**Version** : 2.1 (consolidée)  
**Dernière mise à jour** : 2026-08-14


