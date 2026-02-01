# frozen_string_literal: true

# Service pour générer automatiquement des variantes de produit
# à partir de combinaisons d'options (taille, couleur, etc.)
class ProductVariantGenerator
  attr_reader :product, :option_types, :errors

  def initialize(product, option_types: [])
    @product = product
    @option_types = option_types.is_a?(Array) ? option_types : [ option_types ].compact
    @errors = []
  end

  # Génère toutes les combinaisons de variantes
  # @param base_price_cents [Integer] Prix de base en centimes (optionnel, utilise product.price_cents si nil)
  # @param base_stock_qty [Integer] Stock initial (défaut: 0)
  # @return [Array<ProductVariant>] Liste des variantes créées
  def generate(base_price_cents: nil, base_stock_qty: 0)
    @errors = []
    return [] unless valid?

    base_price_cents ||= product.price_cents || 0
    variants_created = []

    # Générer toutes les combinaisons d'OptionValues
    combinations = generate_combinations

    if combinations.empty?
      @errors << "Aucune combinaison possible avec les options fournies"
      return []
    end

    # Créer les variantes dans une transaction
    ProductVariant.transaction do
      combinations.each do |option_values|
        variant = create_variant(option_values, base_price_cents, base_stock_qty)
        if variant.persisted?
          variants_created << variant
        else
          @errors.concat(variant.errors.full_messages)
          raise ActiveRecord::Rollback if @errors.any?
        end
      end
    end

    variants_created
  end

  # Génère le SKU pour une combinaison d'options
  # Pattern: PRODUIT-OPTION1-OPTION2 (ex: VESTE-RED-M)
  def self.generate_sku(product, option_values)
    base = product.slug&.upcase || product.name&.parameterize&.upcase || "PROD"
    parts = option_values.map { |ov| ov.value.upcase.gsub(/\s+/, "-") }
    [ base, *parts ].join("-")
  end

  # NOUVEAU : Preview avant création
  def self.preview(product_id, option_ids)
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_ids.blank?

    option_types = OptionType.where(id: option_ids)
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_types.empty?

    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_values_array.empty?

    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    count = combinations&.length || 0

    {
      count: count,
      preview_skus: combinations&.first(5)&.map { |combo| generate_sku_template(combo) } || [],
      estimated_time: count * 5,  # secondes
      warning: count > 20 ? "Beaucoup de variantes ! Vérifiez bien." : nil
    }
  end

  # NOUVEAU : Preview avec valeurs individuelles sélectionnées
  def self.preview_from_values(product_id, option_value_ids)
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_value_ids.blank?

    # Convertir en tableau si nécessaire (peut venir comme string depuis params)
    option_value_ids = Array(option_value_ids).map(&:to_i).reject(&:zero?)
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_value_ids.empty?

    option_values = OptionValue.where(id: option_value_ids).includes(:option_type).order(:value)
    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_values.empty?

    # Grouper par option_type
    grouped_by_type = option_values.group_by(&:option_type)
    option_values_array = grouped_by_type.values.map { |values| values.sort_by(&:value) }

    return { count: 0, preview_skus: [], estimated_time: 0, warning: nil } if option_values_array.empty?

    # Vérifier qu'on a au moins 2 groupes pour faire un produit cartésien
    if option_values_array.length < 2
      # Si un seul type d'option, chaque valeur devient une variante
      combinations = option_values_array.first.map { |ov| [ ov ] }
    else
      # Produit cartésien de tous les groupes
      # Exemple: [BLACK, VIOLET].product([L, M, S]) = 6 combinaisons
      combinations = option_values_array.first.product(*option_values_array[1..-1])
    end

    count = combinations&.length || 0

    {
      count: count,
      preview_skus: combinations&.first(5)&.map { |combo| generate_sku_template(combo) } || [],
      estimated_time: count * 5,  # secondes
      warning: count > 20 ? "Beaucoup de variantes ! Vérifiez bien." : nil
    }
  end

  # NOUVEAU : Générer combinaisons avec valeurs individuelles sélectionnées
  # @param base_stock_qty [Integer] Stock initial à appliquer à chaque variante (défaut: 0)
  def self.generate_combinations_from_values(product, option_value_ids, base_stock_qty: 0)
    return 0 if option_value_ids.blank? || product.nil?

    option_values = OptionValue.where(id: option_value_ids).includes(:option_type).order(:value)
    return 0 if option_values.empty?

    # Grouper par option_type
    grouped_by_type = option_values.group_by(&:option_type)
    option_values_array = grouped_by_type.values.map { |values| values.sort_by(&:value) }

    return 0 if option_values_array.empty?

    # Vérifier qu'on a au moins 2 groupes pour faire un produit cartésien
    if option_values_array.length < 2
      # Si un seul type d'option, chaque valeur devient une variante
      combinations = option_values_array.first.map { |ov| [ ov ] }
    else
      # Produit cartésien de tous les groupes
      combinations = option_values_array.first.product(*option_values_array[1..-1])
    end

    return 0 if combinations.nil? || combinations.empty?

    stock_initial = base_stock_qty.to_i

    ActiveRecord::Base.transaction do
      combinations.each do |combo|
        # Générer SKU sûr + unique
        sku = generate_sku_safely(product, combo)

        variant = product.product_variants.build(
          sku: sku,
          price_cents: product.price_cents,
          currency: product.currency || "EUR",
          stock_qty: stock_initial,
          is_active: false  # Créer inactif par défaut, nécessite une image pour activer
        )
        # Ignorer la validation d'image lors de la génération automatique
        variant.instance_variable_set(:@skip_image_validation, true)
        variant.save!(validate: false)

        # Lier les options
        combo.each do |option_value|
          VariantOptionValue.create!(
            variant: variant,
            option_value: option_value
          )
        end
      end
    end

    combinations.length
  end

  # NOUVEAU : Générer combinaisons (avec transaction)
  # @param base_stock_qty [Integer] Stock initial à appliquer à chaque variante (défaut: 0)
  def self.generate_combinations(product, option_ids, base_stock_qty: 0)
    return 0 if option_ids.blank? || product.nil?

    option_types = OptionType.where(id: option_ids)
    return 0 if option_types.empty?

    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    return 0 if option_values_array.empty?

    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    return 0 if combinations.nil? || combinations.empty?

    stock_initial = base_stock_qty.to_i

    ActiveRecord::Base.transaction do
      combinations.each do |combo|
        # Générer SKU sûr + unique
        sku = generate_sku_safely(product, combo)

        variant = product.product_variants.build(
          sku: sku,
          price_cents: product.price_cents,  # NOUVEAU : Héritage prix
          currency: product.currency || "EUR",
          stock_qty: stock_initial,
          is_active: false  # Créer inactif par défaut, nécessite une image pour activer
        )
        # Ignorer la validation d'image lors de la génération automatique
        variant.instance_variable_set(:@skip_image_validation, true)
        variant.save!(validate: false)

        # Lier les options
        combo.each do |option_value|
          VariantOptionValue.create!(
            variant: variant,
            option_value: option_value
          )
        end
      end
    end

    combinations.length
  end

  # NOUVEAU : Générer options manquantes (en édition) avec option_value_ids
  def self.generate_missing_combinations_from_values(product, option_value_ids)
    return 0 if option_value_ids.blank? || product.nil?

    # Convertir en tableau si nécessaire
    option_value_ids = Array(option_value_ids).map(&:to_i).reject(&:zero?)
    return 0 if option_value_ids.empty?

    option_values = OptionValue.where(id: option_value_ids).includes(:option_type).order(:value)
    return 0 if option_values.empty?

    # Grouper par option_type
    grouped_by_type = option_values.group_by(&:option_type)
    option_values_array = grouped_by_type.values.map { |values| values.sort_by(&:value) }

    return 0 if option_values_array.empty?

    # Générer toutes les combinaisons possibles
    if option_values_array.length < 2
      combinations = option_values_array.first.map { |ov| [ ov ] }
    else
      combinations = option_values_array.first.product(*option_values_array[1..-1])
    end

    return 0 if combinations.nil? || combinations.empty?

    # Récupérer les combinaisons existantes pour éviter les doublons
    # Pour chaque variante existante, récupérer ses option_value_ids triés
    existing_combinations = product.product_variants
      .includes(:variant_option_values)
      .map do |variant|
        variant.variant_option_values.map(&:option_value_id).sort
      end

    # Filtrer les combinaisons qui n'existent pas encore
    new_combinations = combinations.reject do |combo|
      combo_ids = combo.map(&:id).sort
      existing_combinations.include?(combo_ids)
    end

    # Log pour déboguer
    Rails.logger.info("ProductVariantGenerator: #{combinations.length} combinaisons possibles, #{existing_combinations.length} existantes, #{new_combinations.length} nouvelles")

    return 0 if new_combinations.empty?

    # Créer les nouvelles variantes
    ActiveRecord::Base.transaction do
      new_combinations.each do |combo|
        sku = generate_sku_safely(product, combo)

        variant = product.product_variants.build(
          sku: sku,
          price_cents: product.price_cents,
          currency: product.currency || "EUR",
          stock_qty: 0,
          is_active: false  # Créer inactif par défaut, nécessite une image pour activer
        )
        # Ignorer la validation d'image lors de la génération automatique
        variant.instance_variable_set(:@skip_image_validation, true)
        variant.save!(validate: false)

        combo.each do |option_value|
          VariantOptionValue.create!(
            variant: variant,
            option_value: option_value
          )
        end
      end
    end

    new_combinations.length
  end

  # NOUVEAU : Générer options manquantes (en édition) avec option_ids (ancien système)
  def self.generate_missing_combinations(product, option_ids)
    return 0 if option_ids.blank? || product.nil?

    existing_options = product.product_variants
      .joins(variant_option_values: :option_value)
      .pluck("option_values.option_type_id")
      .uniq

    new_option_ids = option_ids.map(&:to_i) - existing_options
    return 0 if new_option_ids.empty?

    # Générer seulement les nouvelles combinaisons
    option_types = OptionType.where(id: new_option_ids)
    return 0 if option_types.empty?

    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    return 0 if option_values_array.empty?

    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    return 0 if combinations.nil? || combinations.empty?

    ActiveRecord::Base.transaction do
      combinations.each do |combo|
        sku = generate_sku_safely(product, combo)

        variant = product.product_variants.build(
          sku: sku,
          price_cents: product.price_cents,
          currency: product.currency || "EUR",
          stock_qty: 0,
          is_active: false  # Créer inactif par défaut, nécessite une image pour activer
        )
        # Ignorer la validation d'image lors de la génération automatique
        variant.instance_variable_set(:@skip_image_validation, true)
        variant.save!(validate: false)

        combo.each do |option_value|
          VariantOptionValue.create!(
            variant: variant,
            option_value: option_value
          )
        end
      end
    end

    combinations.length
  end

  # AMÉLIORÉ : SKU génération sûre
  def self.generate_sku_safely(product, combo)
    base_sku = "#{product.slug&.upcase || product.name&.parameterize&.upcase || 'PROD'}-#{combo.map(&:value).join('-').upcase.gsub(/\s+/, '-')}"

    # Vérifier unicité (avec verrouillage pessimiste)
    unless ProductVariant.where(sku: base_sku).exists?
      return base_sku
    end

    # Fallback : ajouter number si existe
    counter = 1
    loop do
      new_sku = "#{base_sku}-#{counter}"
      return new_sku unless ProductVariant.where(sku: new_sku).exists?
      counter += 1
      raise "Impossible de générer un SKU unique" if counter > 100
    end
  end

  def self.generate_sku_template(combo)
    "PRODUCT-#{combo.map(&:value).join('-').upcase.gsub(/\s+/, '-')}"
  end

  private

  def valid?
    if product.nil?
      @errors << "Le produit est requis"
      return false
    end

    if option_types.empty?
      @errors << "Au moins un type d'option est requis"
      return false
    end

    # Vérifier que chaque OptionType a des OptionValues
    option_types.each do |option_type|
      if option_type.option_values.empty?
        @errors << "Le type d'option '#{option_type.name}' n'a pas de valeurs"
        return false
      end
    end

    true
  end

  # Génère toutes les combinaisons possibles d'OptionValues
  # Exemple: [S, M, L] × [Red, Blue] = [[S, Red], [S, Blue], [M, Red], [M, Blue], [L, Red], [L, Blue]]
  def generate_combinations
    return [] if option_types.empty?

    # Récupérer les OptionValues pour chaque OptionType
    option_values_groups = option_types.map { |ot| ot.option_values.to_a }

    # Générer le produit cartésien
    option_values_groups.first.product(*option_values_groups[1..])
  end

  def create_variant(option_values, base_price_cents, base_stock_qty)
    # Générer SKU unique
    sku = self.class.generate_sku(product, option_values)

    # Vérifier que le SKU n'existe pas déjà
    if ProductVariant.exists?(sku: sku)
      # Essayer avec un suffixe numérique
      counter = 1
      loop do
        new_sku = "#{sku}-#{counter}"
        break sku = new_sku unless ProductVariant.exists?(sku: new_sku)
        counter += 1
        raise "Impossible de générer un SKU unique" if counter > 100
      end
    end

    # Créer la variante
    variant = product.product_variants.build(
      sku: sku,
      price_cents: base_price_cents,
      currency: product.currency || "EUR",
      stock_qty: base_stock_qty,
      is_active: false  # Créer inactif par défaut, nécessite une image pour activer
    )

    # Ignorer la validation d'image lors de la génération automatique
    variant.instance_variable_set(:@skip_image_validation, true)

    # Sauvegarder pour avoir l'ID
    unless variant.save(validate: false)
      return variant
    end

    # Associer les OptionValues
    option_values.each do |option_value|
      VariantOptionValue.create!(
        variant: variant,
        option_value: option_value
      )
    end

    variant
  end
end
