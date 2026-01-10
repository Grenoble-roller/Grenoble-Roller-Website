# 🛒 BOUTIQUE - Produits

**Priorité** : 🔴 HAUTE | **Phase** : 2 | **Semaine** : 2  
**Version** : 2.0 | **Dernière mise à jour** : 2025-12-24

---

## 📋 Description

Gestion des produits : CRUD, export, import, publication.

**Fichier actuel** : `app/controllers/admin_panel/products_controller.rb` (existe déjà)

**🎨 Design & UX** : Voir [DESIGN-GUIDELINES.md](./DESIGN-GUIDELINES.md) pour les spécifications complètes du formulaire de création/édition (structure en tabs, sections, validation, etc.)

---

## 🔧 Modifications à Apporter

### **Controller ProductsController**

**Fichier** : `app/controllers/admin_panel/products_controller.rb`

**Modifications** :
1. Ajouter actions `publish` / `unpublish`
2. Utiliser scope `Product.with_associations`
3. Vérifier export CSV fonctionne

**Code** :
```ruby
# Actions à ajouter
def publish
  @product = Product.find(params[:id])
  @product.update(is_active: true)
  redirect_to admin_panel_product_path(@product), notice: 'Produit publié'
end

def unpublish
  @product = Product.find(params[:id])
  @product.update(is_active: false)
  redirect_to admin_panel_product_path(@product), notice: 'Produit dépublié'
end
```

---

## 📝 Routes

**Fichier** : `config/routes.rb`

```ruby
resources :products do
  member do
    post :publish
    post :unpublish
  end
  # ... autres routes
end
```

---

## ✅ Checklist

- [x] Ajouter actions `publish` / `unpublish` dans ProductsController
- [x] Utiliser scope `Product.with_associations` dans index
- [x] Vérifier export CSV fonctionne
- [x] Ajouter routes `publish` / `unpublish`
- [x] Tester publication/dépublication
- [x] Refactoriser formulaire avec structure en tabs
- [x] Implémenter validation en temps réel
- [x] Implémenter auto-save
- [x] Implémenter upload drag & drop pour images

---

## 🎨 Formulaire Produits - Structure en Tabs (IMPLÉMENTÉ)

### **Structure Actuelle**

Le formulaire de création/édition de produits utilise maintenant une **structure en tabs** professionnelle :

1. **Tab Produit** : Informations de base + Images
2. **Tab Prix** : Prix de base et devise
3. **Tab Inventaire** : Stock initial
4. **Tab Variantes** : Gestion des variantes avec preview
5. **Tab SEO** : Meta title et meta description

### **Fichiers Implémentés**

- **Formulaire principal** : `app/views/admin_panel/products/_form.html.erb`
  - Structure en tabs Bootstrap
  - Header avec actions (Enregistrer, Publier, Aperçu)
  - Barre de statut auto-save en bas
  - Script d'initialisation des tabs

- **Partial Upload Images** : `app/views/admin_panel/products/_image_upload.html.erb`
  - Zone drag & drop
  - Preview des images
  - Support URL image

- **Partial Variantes** : `app/views/admin_panel/products/_variants_section.html.erb`
  - Sélection options avec preview
  - Génération automatique ou manuelle

### **Controllers Stimulus**

- **`product_form_controller.js`** : Validation en temps réel, auto-save, preview variants
- **`image_upload_controller.js`** : Drag & drop, preview images

### **Fonctionnalités**

✅ Validation en temps réel avec feedback visuel  
✅ Auto-save toutes les 30 secondes (debounce 2s)  
✅ Compteurs de caractères (nom, meta title, meta description)  
✅ Génération automatique du slug depuis le nom  
✅ Preview variants avant génération  
✅ Upload drag & drop avec preview  
✅ Design Liquid Glass appliqué

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
