module ApplicationHelper
  include ActionView::Helpers::TextHelper
  # Pagy 43 : Utilise series_nav avec :bootstrap comme style
  def pagy_bootstrap_nav(pagy, **options)
    pagy.series_nav(:bootstrap, **options)
  end

  def pagy_nav(pagy, **options)
    pagy.series_nav(**options)
  end

  def pagy_info(pagy, **options)
    pagy.info_tag(**options)
  end

  # Alias de la méthode originale pluralize avant surcharge
  alias_method :original_pluralize, :pluralize

  def cart_items_count
    return 0 unless session[:cart]
    session[:cart].values.sum(&:to_i)
  end

  def format_price(amount_cents)
    return "Prix non disponible" if amount_cents.nil?
    amount = amount_cents / 100.0
    # Formater sans décimales si c'est un nombre entier
    formatted = amount == amount.to_i ? amount.to_i.to_s : sprintf("%.2f", amount)
    formatted.gsub(".", ",") + "€"
  end

  # Formater le prix d'un événement selon les règles françaises
  # - Si 0.00 → "Gratuit"
  # - Sinon : montant sans décimales si .00, avec "euros" après
  # - Format : "15 euros" ou "15,50 euros" (pas de "EUR" avant)
  def format_event_price(price_cents)
    return "Gratuit" if price_cents.nil? || price_cents == 0

    amount = price_cents / 100.0

    # Formater sans décimales si c'est un nombre entier
    if amount == amount.to_i
      "#{amount.to_i} euros"
    else
      # Formater avec 2 décimales et remplacer le point par une virgule
      formatted = sprintf("%.2f", amount).gsub(".", ",")
      # Enlever les zéros inutiles à la fin (ex: "15,50" → "15,5" si on veut, mais on garde 2 décimales pour cohérence)
      "#{formatted} euros"
    end
  end

  # Helper supprimé : plus d'image par défaut, l'image est obligatoire

  # Sécurise une URL externe en validant qu'elle commence par http:// ou https://
  # Retourne nil si l'URL n'est pas valide, ce qui empêche les attaques XSS
  def safe_external_url(url)
    return nil if url.blank?

    url = url.to_s.strip
    # Valider que l'URL commence par http:// ou https://
    if url.match?(/\Ahttps?:\/\//i)
      url
    else
      nil
    end
  end

  # Surcharge de pluralize pour gérer correctement le français
  # Gère les expressions composées comme "place disponible" → "places disponibles"
  # Règle : 0 et 1 = singulier, 2+ = pluriel
  def pluralize(count, singular, plural = nil)
    # Si plural est fourni explicitement, utiliser la méthode originale de Rails
    if plural.present?
      return original_pluralize(count, singular, plural)
    end

    # Gérer le français : 0 et 1 = singulier, 2+ = pluriel
    return "#{count} #{singular}" if count == 0 || count == 1

    # Règles de pluralisation françaises pour les expressions courantes
    plural_rules = {
      "inscrit" => "inscrits",
      "place disponible" => "places disponibles",
      "place adhérent" => "places adhérents",
      "place découverte" => "places découvertes",
      "boucle" => "boucles"
    }

    # Si on a une règle spécifique, l'utiliser
    if plural_rules.key?(singular)
      pluralized = plural_rules[singular]
    else
      # Sinon, utiliser la méthode originale de Rails (ajoute "s" à la fin)
      pluralized = singular.pluralize
    end

    "#{count} #{pluralized}"
  end
end
