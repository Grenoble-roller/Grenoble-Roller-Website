# frozen_string_literal: true

module AdminPanelHelper
  # Afficher le breadcrumb sauf sur le dashboard
  def show_breadcrumb?
    !(controller_name == "dashboard" && action_name == "index")
  end

  # Vérifier si l'utilisateur est admin
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def admin_user?
    return false unless current_user&.role

    current_user.role.level.to_i >= 60
  end

  # Helper pour vérifier les permissions sidebar par niveau
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def can_access_admin_panel?(min_level = 60)
    return false unless current_user&.role

    current_user.role.level.to_i >= min_level
  end

  # Helper pour vérifier si on peut voir les initiations (level >= 40)
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def can_view_initiations?
    can_access_admin_panel?(40)
  end

  # Helper pour vérifier si on peut voir la boutique (level >= 60)
  def can_view_boutique?
    can_access_admin_panel?(60)
  end

  # Helper pour vérifier si un controller est actif dans AdminPanel
  def admin_panel_active?(controller_name, action_name = nil)
    return false unless controller.class.name.start_with?("AdminPanel::")

    if action_name
      controller_name.to_s == controller.controller_name && action_name.to_s == controller.action_name
    else
      controller_name.to_s == controller.controller_name
    end
  end

  # Traduit les statuts d'attendance en français
  def attendance_status_fr(status)
    case status.to_s
    when "pending"
      "En attente"
    when "registered"
      "Inscrit"
    when "paid"
      "Payé"
    when "present"
      "Présent"
    when "absent"
      "Absent"
    when "no_show"
      "No-show"
    when "canceled"
      "Annulé"
    else
      status.to_s.humanize
    end
  end

  # Traduit les statuts de waitlist en français
  def waitlist_status_fr(status)
    case status.to_s
    when "pending"
      "En attente"
    when "notified"
      "Notifié"
    when "converted"
      "Converti"
    when "cancelled"
      "Annulé"
    else
      status.to_s.humanize
    end
  end

  # Parse les arguments JSON d'un job ActionMailer pour extraire mailer et méthode
  # SolidQueue peut stocker les arguments comme String JSON ou déjà désérialisés (Array/Hash)
  # Format ActiveJob: { "arguments": ["MailerClass", "method_name", "deliver_now", {...}] }
  # Format direct: ["MailerClass", "method_name", "deliver_now", {...}]
  def parse_mailer_info(arguments_data)
    return { mailer: nil, method: nil } if arguments_data.blank?

    begin
      # Parser si c'est une String JSON
      parsed_data = if arguments_data.is_a?(String)
        JSON.parse(arguments_data)
      else
        arguments_data
      end

      # Si c'est un Hash avec la clé "arguments" (format ActiveJob)
      if parsed_data.is_a?(Hash) && parsed_data["arguments"].is_a?(Array)
        args = parsed_data["arguments"]
      # Si c'est directement un Array
      elsif parsed_data.is_a?(Array)
        args = parsed_data
      else
        return { mailer: nil, method: nil }
      end

      if args.is_a?(Array) && args.length >= 2
        { mailer: args[0], method: args[1] }
      else
        { mailer: nil, method: nil }
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse mailer info: #{e.message}")
      { mailer: nil, method: nil }
    rescue => e
      Rails.logger.error("Error parsing mailer info: #{e.class} - #{e.message}")
      { mailer: nil, method: nil }
    end
  end
end
