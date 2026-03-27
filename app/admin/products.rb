ActiveAdmin.register Product do
  menu priority: 1, label: "Produits", parent: "Boutique"

  includes :category

  permit_params :category_id, :name, :slug, :description, :price_cents,
                :currency, :stock_qty, :is_active, :image

  scope :all, default: true
  scope("Actifs") { |products| products.where(is_active: true) }
  scope("Inactifs") { |products| products.where(is_active: false) }
  scope("En rupture de stock") { |products| products.where("stock_qty <= 0") }
  scope("En stock") { |products| products.where("stock_qty > 0") }

  index do
    selectable_column
    id_column
    column :name
    column :category
    column :slug
    column :is_active do |product|
      status_tag(product.is_active ? "actif" : "inactive", class: product.is_active ? "ok" : "warning")
    end
    column :price_cents do |product|
      number_to_currency(product.price_cents / 100.0, unit: product.currency)
    end
    column :stock_qty do |product|
      if product.stock_qty <= 0
        status_tag("Rupture", class: "error")
      elsif product.stock_qty < 10
        status_tag(product.stock_qty, class: "warning")
      else
        product.stock_qty
      end
    end
    column :created_at
    actions
  end

  filter :name
  filter :category
  filter :is_active
  filter :currency
  filter :created_at

  show do
    attributes_table do
      row :name
      row :category
      row :slug
      row :description
      row :price_cents do |product|
        number_to_currency(product.price_cents / 100.0, unit: product.currency)
      end
      row :stock_qty do |product|
        if product.stock_qty <= 0
          status_tag("Rupture de stock", class: "error")
        elsif product.stock_qty < 10
          status_tag("#{product.stock_qty} (stock faible)", class: "warning")
        else
          "#{product.stock_qty} en stock"
        end
      end
      row :currency
      row :is_active do |product|
        status_tag(product.is_active ? "Actif" : "Inactif", class: product.is_active ? "ok" : "warning")
      end
      row :image do |product|
        if product.image.attached?
          image_tag(product.image.variant(resize_to_limit: [ 300, 300 ]), style: "border-radius: 8px; max-width: 300px;")
        else
          status_tag("Aucune image", class: "warning")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Variantes du produit" do
      div style: "margin-bottom: 15px;" do
        link_to "➕ Créer une nouvelle variante", new_activeadmin_product_variant_path(product_variant: { product_id: product.id }),
                class: "button",
                style: "background: #337ab7; color: white; padding: 8px 15px; border-radius: 4px; text-decoration: none; display: inline-block;"
      end

      if product.product_variants.any?
        table_for product.product_variants.includes(:option_values) do
          column :sku
          column "Options" do |variant|
            options = variant.option_values.includes(:option_type).sort_by { |ov| [ ov.option_type.name, ov.value ] }.map do |ov|
              type_name = ov.option_type.name == "color" ? "Couleur" : (ov.option_type.name == "size" ? "Taille" : ov.option_type.presentation)
              "#{type_name}: #{ov.presentation}"
            end
            options.any? ? options.join(", ") : "Aucune option"
          end
          column :price_cents do |variant|
            number_to_currency(variant.price_cents / 100.0, unit: variant.currency)
          end
          column :stock_qty do |variant|
            if variant.stock_qty <= 0
              status_tag("Rupture", class: "error")
            elsif variant.stock_qty < 10
              status_tag(variant.stock_qty, class: "warning")
            else
              variant.stock_qty
            end
          end
          column :is_active do |variant|
            status_tag(variant.is_active ? "Actif" : "Inactif", class: variant.is_active ? "ok" : "warning")
          end
          column "Actions" do |variant|
            div do
              link_to "Voir", activeadmin_product_variant_path(variant), class: "button", style: "margin-right: 5px; display: inline-block;"
              link_to "Modifier", edit_activeadmin_product_variant_path(variant), class: "button", style: "margin-right: 5px; display: inline-block;"
              link_to "Supprimer", activeadmin_product_variant_path(variant), method: :delete,
                      class: "button",
                      style: "background: #d9534f; color: white; display: inline-block;",
                      data: { confirm: "Êtes-vous sûr de vouloir supprimer cette variante ?" }
            end
          end
        end
      else
        para "Aucune variante pour ce produit. Créez-en une pour pouvoir vendre ce produit.", style: "color: #666; padding: 10px;"
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Produit" do
      para "ℹ️ Le produit sert à regrouper les variantes (couleur/taille) et définir les informations communes (description, image, catégorie).",
           style: "color: #666; margin-bottom: 15px; padding: 10px; background: #f8f9fa; border-radius: 4px;"
      f.input :category
      f.input :name,
              hint: "Nom du produit (ex: 'Veste Grenoble Roller'). Les variantes seront créées séparément."
      f.input :slug
      f.input :description
      f.input :price_cents,
              label: "Prix (cents)",
              hint: "Prix de base en centimes. Chaque variante peut avoir son propre prix."
      f.input :currency, input_html: { value: f.object.currency || "EUR" }
      f.input :stock_qty,
              hint: "⚠️ ATTENTION : Le stock réel est géré au niveau des variantes, pas ici. Ce champ n'est utilisé que pour affichage."
      f.input :is_active,
              hint: "Désactiver pour masquer le produit et toutes ses variantes sur le site"
      f.input :image, as: :file, hint: "Upload une image (recommandé)"
    end

    f.actions
  end

  controller do
    def destroy
      @product = resource
      if @product.destroy
        redirect_to collection_path, notice: "Le produit ##{@product.id} a été supprimé avec succès."
      else
        redirect_to resource_path(@product), alert: "Impossible de supprimer le produit : #{@product.errors.full_messages.join(', ')}"
      end
    end
  end
end
