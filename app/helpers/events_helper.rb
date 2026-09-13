module EventsHelper
  # Helper pour obtenir les routes de manière polymorphique selon le type d'événement
  def event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
  end

  def edit_event_path_for(event)
    event.is_a?(Event::Initiation) ? edit_initiation_path(event) : edit_event_path(event)
  end

  def ical_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_path(event, format: :ics) : event_path(event, format: :ics)
  end

  def toggle_reminder_event_path_for(event)
    event.is_a?(Event::Initiation) ? toggle_reminder_initiation_attendances_path(event) : toggle_reminder_event_attendances_path(event)
  end

  def attend_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_attendances_path(event) : event_attendances_path(event)
  end

  def cancel_attendance_event_path_for(event, attendance = nil)
    # Toujours utiliser la route collection car destroy est une collection
    # Le paramètre child_membership_id sera passé dans les params du formulaire
    event.is_a?(Event::Initiation) ? initiation_attendances_path(event) : event_attendances_path(event)
  end

  def events_index_path_for(event)
    event.is_a?(Event::Initiation) ? initiations_path : events_path
  end

  def events_index_label_for(event)
    event.is_a?(Event::Initiation) ? "Toutes les initiations" : "Tous les événements"
  end

  def join_waitlist_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_waitlist_entries_path(event) : event_waitlist_entries_path(event)
  end

  def leave_waitlist_event_path_for(event, waitlist_entry = nil)
    # Toujours utiliser la route collection car destroy est une collection
    # Le paramètre child_membership_id sera passé dans les params du formulaire
    event.is_a?(Event::Initiation) ? initiation_waitlist_entries_path(event) : event_waitlist_entries_path(event)
  end

  def convert_waitlist_to_attendance_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/convert_to_attendance
    convert_to_attendance_waitlist_entry_path(waitlist_entry)
  end

  def refuse_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/refuse
    refuse_waitlist_entry_path(waitlist_entry)
  end

  def confirm_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/confirm
    confirm_waitlist_entry_path(waitlist_entry)
  end

  def decline_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/decline
    decline_waitlist_entry_path(waitlist_entry)
  end

  # Variantes _url pour les emails (URLs absolues)
  def confirm_waitlist_event_url_for(event, waitlist_entry)
    confirm_waitlist_entry_url(waitlist_entry)
  end

  def decline_waitlist_event_url_for(event, waitlist_entry)
    decline_waitlist_entry_url(waitlist_entry)
  end

  # Affiche la distance : une valeur pour une boucle, ou "5 km + 7 km" pour plusieurs
  def format_event_distance(event)
    values = event.loop_distance_km_values
    return nil if values.empty?

    values.map { |km| format_distance_km(km) }.join(" + ")
  end

  def route_difficulty_label(difficulty)
    case difficulty
    when "easy" then "Facile"
    when "medium" then "Moyen"
    when "hard" then "Difficile"
    else difficulty.to_s.humanize
    end
  end

  def event_loop_columns_class(loops_count)
    case loops_count
    when 2 then "col-12 col-md-6"
    when 3 then "col-12 col-md-4"
    else "col-12 col-sm-6 col-xl-3"
    end
  end

  def event_payment_mode_description(event)
    return "Gratuit" if event.price_cents.to_i <= 0

    if event.requires_online_payment?
      "Paiement en ligne via Grenoble Roller (panier, 15 min pour payer)"
    else
      "Prix informatif — paiement géré par l'organisateur (inscription directe)"
    end
  end

  def route_map_viewer_data(route, title:)
    return {} unless route&.map_image&.attached?

    pswp_gallery_item_data(route.map_image, title: title)
  end

  def event_cover_viewer_data(event)
    return {} unless event.cover_image.attached?

    pswp_gallery_item_data(event.cover_image, title: event.title)
  end

  # PhotoSwipe gallery item attrs (parent mounts route-image-viewer). No Stimulus actions here —
  # Rails HTML-escapes "->" in data-action when set via tag helpers.
  def pswp_gallery_item_data(attachment, title:)
    data = { pswp_title: title }
    meta = attachment.blob.metadata || {}
    data[:pswp_width] = meta["width"] if meta["width"].present?
    data[:pswp_height] = meta["height"] if meta["height"].present?
    data
  end

  # Active Storage variants only work on raster images (not SVG).
  def route_map_image_path(route, resize_to: nil)
    return unless route&.map_image&.attached?

    attachment = route.map_image
    if resize_to.present? && attachment.variable?
      rails_representation_path(attachment.variant(resize_to_limit: resize_to))
    else
      rails_storage_proxy_path(attachment, only_path: true)
    end
  end

  # Formate la durée d'un événement et calcule l'heure de fin
  def event_organizer_display(event)
    {
      name: event.display_organizer_name,
      url: safe_external_url(event.display_organizer_url)
    }
  end

  def render_event_organizer(event)
    display = event_organizer_display(event)
    return content_tag(:span, display[:name]) if display[:url].blank?

    link_to(display[:name], display[:url], target: "_blank", rel: "noopener noreferrer")
  end

  def format_event_duration(event)
    return nil unless event.start_at && event.duration_min

    # Calculer l'heure de fin
    end_time = event.start_at + event.duration_min.minutes

    # Formater la durée (ex: 60 min = 1h, 105 min = 1h45)
    hours = event.duration_min / 60
    minutes = event.duration_min % 60

    duration_text = if hours > 0 && minutes > 0
      "#{hours}h#{minutes.to_s.rjust(2, '0')}"
    elsif hours > 0
      "#{hours}h"
    else
      "#{minutes}min"
    end

    # Formater les heures de début et fin (format: "10h15")
    start_time_text = event.start_at.strftime("%Hh%M")
    end_time_text = end_time.strftime("%Hh%M")

    "#{duration_text} (#{start_time_text} - #{end_time_text})"
  end

  private

  def format_distance_km(km)
    "#{number_with_precision(km, precision: 1, strip_insignificant_zeros: true)} km"
  end
end
