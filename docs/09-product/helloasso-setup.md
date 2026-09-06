# HelloAsso - Guide de Configuration et Setup

**Date** : 2026-08-14  
**Version** : 2.1  
**Status** : ✅ Documentation consolidée (mise à jour — HelloAsso intégré, checkout + polling actifs)

---

## 📋 Vue d'ensemble

Ce document consolide toute la documentation relative à la configuration et au setup de l'intégration HelloAsso pour Grenoble Roller, incluant :
- Récupération des informations API
- Ajout des credentials Rails
- Configuration du polling automatique

---

## 🔐 ÉTAPE 1 : Récupération des Informations API

### **Checklist Préliminaire**

- [ ] **1. Créer/Accéder au compte Hello Asso de l'association**
  - URL : https://www.helloasso.com/
  - Se connecter avec le compte de l'association Grenoble Roller
  - Vérifier que le compte est actif et validé

- [ ] **2. Accéder à la section API**
  - Aller dans "Mon compte" → "Intégrations et API"
  - Ou directement : https://www.helloasso.com/associations/grenoble-roller/parametres/api
  - Vérifier les permissions d'accès API

- [ ] **3. Obtenir les identifiants OAuth2**
  - **Client ID** : Identifiant public de l'application
  - **Client Secret** : Secret à garder confidentiel (jamais dans le code)
  - **Organization Slug** : Identifiant de l'organisation (ex: "grenoble-roller")
  - ⚠️ **IMPORTANT** : Noter ces informations dans un endroit sécurisé

- [ ] **4. Comprendre le flux OAuth2**
  - Hello Asso utilise OAuth2 pour l'authentification
  - Il faut obtenir un **token d'accès** (access token) avant chaque requête API
  - Le token a une durée de vie limitée (à vérifier dans la doc)

- [ ] **5. Consulter la documentation API**
  - Documentation officielle : https://api.helloasso.com/v5/docs
  - Documentation développeur : https://dev.helloasso.com/
  - Endpoints disponibles et leurs paramètres

- [ ] **6. Tester dans l'environnement Sandbox**
  - Créer un compte sandbox si nécessaire
  - Tester l'authentification OAuth2
  - Tester la création d'une commande de test

---

### **Informations à Récupérer**

#### **1. Identifiants OAuth2**

Ces informations doivent être stockées dans les **Rails credentials** (jamais dans le code) :

```yaml
# config/credentials.yml.enc
helloasso:
  client_id: "votre_client_id_sandbox"        # Client ID sandbox
  client_secret: "votre_client_secret_sandbox" # Client Secret sandbox
  organization_slug: "grenoble-roller"        # À confirmer
  environment: "sandbox"                      # ⚠️ TOUJOURS "sandbox" pour commencer
  # Pour production (à ajouter plus tard) :
  # client_id_production: "votre_client_id_production"
  # client_secret_production: "votre_client_secret_production"
```

#### **2. URLs API**

**Environnement SANDBOX** (Tests - À utiliser en premier) ⚠️
- **Base URL API** : `https://api.helloasso-sandbox.com/v5`
- **URL OAuth2** : `https://api.helloasso-sandbox.com/oauth2`
- **Obtenir vos tokens** : https://api.helloasso-sandbox.com/oauth2
- **Faire vos appels API** : https://api.helloasso-sandbox.com/v5

**Environnement PRODUCTION** (À utiliser uniquement après tests complets)
- **Base URL API** : `https://api.helloasso.com/v5`
- **URL OAuth2** : `https://api.helloasso.com/oauth2`

#### **3. Endpoints Nécessaires**

**Authentification**
- `POST https://api.helloasso-sandbox.com/oauth2/token` - Obtenir un token d'accès (SANDBOX)
- `POST https://api.helloasso.com/oauth2/token` - Obtenir un token d'accès (PRODUCTION)

**Checkout (intention de paiement)**
- `POST https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/checkout-intents`
  - Utilisé par `HelloassoService.create_checkout_intent`
  - Retourne un `id` et une `redirectUrl` (URL de paiement HelloAsso)

**Commandes / Paiements (lecture uniquement)**
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/orders/{orderId}` - Lire l'état d'une commande
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/payments/{paymentId}` - Lire l'état d'un paiement

> ⚠️ **Remplacer `helloasso-sandbox.com` par `helloasso.com` pour la production**

---

### **Documentation à Consulter**

**Liens Essentiels**

1. **Documentation API v5**
   - URL : https://api.helloasso.com/v5/docs
   - Endpoints disponibles, paramètres, réponses

2. **Documentation Développeur**
   - URL : https://dev.helloasso.com/
   - Guides d'intégration, exemples de code

3. **Guide OAuth2**
   - URL : https://dev.helloasso.com/docs/introduction-%C3%A0-lapi-de-helloasso
   - Flux d'authentification détaillé

4. **Centre d'aide**
   - URL : https://centredaide.helloasso.com/
   - FAQ et support

---

### **Flux OAuth2**

#### **Étape 1 : Obtenir un Token d'Accès (SANDBOX)**

```http
POST https://api.helloasso-sandbox.com/oauth2
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=VOTRE_CLIENT_ID_SANDBOX
&client_secret=VOTRE_CLIENT_SECRET_SANDBOX
```

**Réponse attendue** :
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

#### **Étape 2 : Utiliser le Token pour les Requêtes API (SANDBOX)**

```http
GET https://api.helloasso-sandbox.com/v5/organizations/grenoble-roller/orders
Authorization: Bearer {access_token}
```

> ⚠️ **IMPORTANT** : Utiliser les URLs sandbox (`api.helloasso-sandbox.com`) pour tous les tests !

---

### **⚠️ RÈGLE D'OR : TOUS LES TESTS EN SANDBOX AVANT PRODUCTION**

**URLs Sandbox** :
- **OAuth2** : https://api.helloasso-sandbox.com/oauth2
- **API v5** : https://api.helloasso-sandbox.com/v5

**Pourquoi Tester en Sandbox ?**
- ✅ Tester sans risquer de vrais paiements
- ✅ Valider le flux complet avant production
- ✅ Déboguer les erreurs sans impact
- ✅ Tester tous les scénarios (succès, échec, annulation)
- ✅ Valider les webhooks sans impact réel

**Actions à Faire**
- [ ] Créer un compte sandbox Hello Asso (si nécessaire)
- [ ] Obtenir les identifiants sandbox (Client ID, Client Secret)
- [ ] **Utiliser les URLs sandbox** : `api.helloasso-sandbox.com`
- [ ] Tester l'authentification OAuth2 en sandbox
- [ ] Créer une commande de test en sandbox
- [ ] Tester les webhooks en sandbox (utiliser ngrok ou équivalent pour exposer localhost)
- [ ] Valider TOUT le flux en sandbox avant de passer en production

**⚠️ Passage en Production**

**NE PAS passer en production tant que :**
- [ ] Tous les tests sandbox sont OK
- [ ] Le flux complet fonctionne (création commande → paiement → webhook)
- [ ] Les erreurs sont gérées correctement
- [ ] Les webhooks sont testés et fonctionnels

---

## 🔐 ÉTAPE 2 : Ajouter les Credentials Rails

### **PRÉREQUIS**

Vous devez avoir :
- ✅ **Client ID** Hello Asso (sandbox)
- ✅ **Client Secret** Hello Asso (sandbox)
- ✅ **Organization Slug** (ex: "grenoble-roller") - À confirmer

---

### **ÉTAPE 1 : Ouvrir les Credentials**

```bash
bin/rails credentials:edit
```

Cette commande va :
1. Décrypter `config/credentials.yml.enc`
2. Ouvrir le fichier dans votre éditeur par défaut
3. Vous permettre d'ajouter vos identifiants

---

### **ÉTAPE 2 : Ajouter la Structure Hello Asso**

Dans le fichier qui s'ouvre, ajoutez la section suivante :

```yaml
# ... autres credentials existants ...

helloasso:
  client_id: "VOTRE_CLIENT_ID_ICI"
  client_secret: "VOTRE_CLIENT_SECRET_ICI"
  organization_slug: "grenoble-roller"  # À confirmer avec votre compte
  environment: "sandbox"  # ⚠️ Toujours "sandbox" pour commencer
```

**Exemple complet** :

```yaml
secret_key_base: <votre_secret_key_base_existant>

helloasso:
  client_id: "abc123xyz789"
  client_secret: "secret_abc123xyz789_secret"
  organization_slug: "grenoble-roller"
  environment: "sandbox"
```

---

### **ÉTAPE 3 : Sauvegarder et Fermer**

1. **Sauvegarder** le fichier (Ctrl+S ou Cmd+S)
2. **Fermer** l'éditeur
3. Rails va automatiquement :
   - Re-chiffrer le fichier
   - Sauvegarder dans `config/credentials.yml.enc`

---

### **ÉTAPE 4 : Vérifier que les Credentials sont Bien Ajoutés**

```bash
bin/rails credentials:show
```

Vous devriez voir votre section `helloasso` avec les valeurs (masquées pour la sécurité).

**Ou tester dans la console Rails** :

```bash
bin/rails console
```

Puis dans la console :

```ruby
# Vérifier que les credentials sont accessibles
Rails.application.credentials.dig(:helloasso, :client_id)
# => "votre_client_id"

Rails.application.credentials.dig(:helloasso, :client_secret)
# => "votre_client_secret"

Rails.application.credentials.dig(:helloasso, :organization_slug)
# => "grenoble-roller"

Rails.application.credentials.dig(:helloasso, :environment)
# => "sandbox"
```

---

### **⚠️ SÉCURITÉ - RÈGLES IMPORTANTES**

#### ✅ **À FAIRE** :
- ✅ Stocker les credentials dans `config/credentials.yml.enc` (chiffré)
- ✅ Utiliser `bin/rails credentials:edit` pour modifier
- ✅ Vérifier que `config/master.key` est dans `.gitignore`
- ✅ Ne jamais commiter `config/master.key`

#### ❌ **À NE JAMAIS FAIRE** :
- ❌ Mettre les credentials dans le code source
- ❌ Mettre les credentials dans un fichier `.env` non chiffré
- ❌ Commiter `config/master.key` dans Git
- ❌ Partager les credentials par email ou chat non sécurisé

---

### **🔄 Pour la Production (Plus Tard)**

Quand vous passerez en production, vous pourrez ajouter :

```yaml
helloasso:
  client_id: "votre_client_id_sandbox"
  client_secret: "votre_client_secret_sandbox"
  organization_slug: "grenoble-roller"
  environment: "sandbox"
  # Production (à ajouter quand vous passerez en prod)
  client_id_production: "votre_client_id_production"
  client_secret_production: "votre_client_secret_production"
```

Ou utiliser des variables d'environnement en production :

```bash
# En production
export HELLOASSO_CLIENT_ID="votre_client_id_production"
export HELLOASSO_CLIENT_SECRET="votre_client_secret_production"
```

---

### **📝 NOTES**

- Le fichier `config/credentials.yml.enc` est **chiffré** et peut être commité dans Git
- Le fichier `config/master.key` est **déchiffré** et **NE DOIT JAMAIS** être commité
- Les credentials sont accessibles via `Rails.application.credentials.dig(:helloasso, :key)`

---

## ⚙️ ÉTAPE 3 : Configuration Polling Automatique

### **Solution : Whenever Gem**

**Pourquoi Whenever ?**
- ✅ Simple et éprouvé
- ✅ Syntaxe Ruby claire
- ✅ Gère les environnements (dev/prod)
- ✅ Intégration facile avec Rails

---

### **INSTALLATION**

#### 1. Installer la gem

```bash
bundle install
```

La gem `whenever` est déjà dans le `Gemfile`.

#### 2. Initialiser Whenever (déjà fait)

Le fichier `config/schedule.rb` est déjà créé avec la configuration.

#### 3. Vérifier la configuration

```bash
# Voir la cron générée (sans l'installer)
whenever

# Voir avec les variables d'environnement
whenever --set environment=production
```

---

### **CONFIGURATION**

#### Fichier `config/schedule.rb`

```ruby
# Sync HelloAsso payments toutes les 5 minutes
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end
```

#### Déployer la cron

```bash
# En développement (optionnel)
whenever --update-crontab --set environment=development

# En production (OBLIGATOIRE)
whenever --update-crontab --set environment=production
```

⚠️ **IMPORTANT** : À faire sur le serveur de production après chaque déploiement.

---

### **TEST**

#### Tester manuellement

```bash
# Tester la rake task
bin/rails helloasso:sync_payments

# Vérifier les logs
tail -f log/development.log | grep Helloasso
```

#### Vérifier que la cron est installée

```bash
# Voir les crons de l'utilisateur
crontab -l

# Devrait afficher quelque chose comme :
# */5 * * * * /bin/bash -l -c 'cd /path/to/app && RAILS_ENV=production bundle exec rails runner "Rake::Task[\"helloasso:sync_payments\"].invoke" >> log/cron.log 2>&1'
```

---

### **AUTO-REFRESH SUR LA PAGE COMMANDE**

#### Fonctionnalité

Sur la page détail d'une commande `pending`, l'utilisateur voit :
- ✅ **Alerte** : "⏳ Paiement en attente - Vérification automatique en cours..."
- ✅ **Bouton** : "🔄 Vérifier maintenant" (force la vérification)
- ✅ **Auto-poll JS** : Vérifie automatiquement toutes les 10 secondes pendant 1 minute

#### Routes ajoutées

- `POST /orders/:id/check-payment` → Force la vérification du paiement
- `GET /orders/:id/payment-status` → Retourne le statut en JSON (pour le polling JS)

#### Comportement

1. **Utilisateur paie sur HelloAsso**
2. **Revient sur la page commande** → Voit l'alerte "Paiement en attente"
3. **Auto-poll démarre** → Vérifie toutes les 10s pendant 1 min
4. **Si statut change** → Page se recharge automatiquement
5. **Si pas de changement après 1 min** → Auto-poll s'arrête
6. **Bouton "Vérifier maintenant"** → Force une vérification immédiate

---

### **MONITORING**

#### Logs

Les logs du polling sont dans :
- `log/cron.log` (cron automatique)
- `log/development.log` ou `log/production.log` (logs Rails)

#### Vérifier les paiements en attente

```ruby
# Dans Rails console
Payment.where(provider: 'helloasso', status: 'pending').count
Payment.where(provider: 'helloasso', status: 'pending').where('created_at > ?', 1.day.ago)
```

---

### **⚠️ POINTS D'ATTENTION**

#### Production

- ✅ **Cron doit être installé** : `whenever --update-crontab` après chaque déploiement
- ✅ **Vérifier les logs** : `tail -f log/cron.log`
- ✅ **Monitoring** : Surveiller les erreurs dans les logs

#### Performance

- ✅ **Scope limité** : Seulement les paiements des 24 dernières heures
- ✅ **Gestion d'erreurs** : Continue même si un paiement échoue
- ✅ **Pas de surcharge** : 1 requête API par paiement pending

---

### **✅ CHECKLIST**

- [x] Gem `whenever` ajoutée au Gemfile
- [x] `config/schedule.rb` créé
- [x] Rake task `helloasso:sync_payments` fonctionnelle
- [x] Routes `check_payment` et `payment_status` ajoutées
- [x] Actions controller implémentées
- [x] Alerte + bouton + auto-poll JS dans `orders/show.html.erb`
- [ ] **À faire en production** : `whenever --update-crontab`

---

## 📚 RESSOURCES

### **Documentation HelloAsso**
- API v5 Docs : https://api.helloasso.com/v5/docs
- Dev Portal : https://dev.helloasso.com/
- Swagger Sandbox : https://api.helloasso-sandbox.com/v5/swagger/ui/index

### **Documentation interne**
- Flux boutique HelloAsso : `docs/09-product/flux-boutique-helloasso.md`
- Adhésions complètes : `docs/09-product/adhesions-complete.md`

---

**Dernière mise à jour** : 2026-08-14  
**Version** : 2.0

