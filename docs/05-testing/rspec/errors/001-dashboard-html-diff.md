# Erreur #001 : Dashboard GET /admin-panel – diff HTML

**Date d'analyse** : 2026-02-24  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Admin panel

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/admin_panel/dashboard_spec.rb`
- **Ligne** : 21
- **Test** : `GET /admin-panel when user is admin (level 60) displays dashboard`
- **Commande pour reproduire** :
  ```bash
  docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/requests/admin_panel/dashboard_spec.rb:21
  ```

---

## 🔴 Erreur (constatée en conteneur)

1. **Could not find a valid mapping for #<User ...>** dans `before { sign_in admin_user }` (Devise en request spec).
2. Assertion `include('Tableau de bord')` alors que la vue affiche **Dashboard Admin**.

---

## 🔍 Analyse

### Constats
- Le spec utilisait `sign_in` au lieu de `login_user` → échec du mapping Devise en request.
- La vue `admin_panel/dashboard/index.html.erb` utilise le titre "Dashboard Admin", pas "Tableau de bord".

### Cause Probable
- Authentification : utiliser le helper `login_user` (RequestAuthenticationHelper) comme les autres specs admin.
- Contenu : assertion obsolète (texte changé dans la vue).

---

## 💡 Solutions Appliquées

1. Remplacer `sign_in admin_user` (et tous les `sign_in` du fichier) par `login_user admin_user` (idem pour superadmin, organizer, regular_user).
2. Remplacer `expect(response.body).to include('Tableau de bord')` par `include('Dashboard Admin')`.

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (helper d’auth + assertion obsolète)

---

## 📊 Statut

🟢 **RÉSOLU** – 6 examples, 0 failures (dashboard_spec.rb).

---

## 🔗 Erreurs Similaires

- Aucune

---

## 📝 Notes

- Voir spec/requests/admin_panel/README.md : « Utiliser login_user au lieu de sign_in dans les tests request ».

---

## ✅ Actions à Effectuer

1. [x] Utiliser `login_user` au lieu de `sign_in` dans dashboard_spec.rb.
2. [x] Mettre à jour l’assertion vers "Dashboard Admin".
3. [x] Rejouer le spec et mettre à jour cette fiche.
