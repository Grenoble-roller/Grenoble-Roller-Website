# Job pour envoyer un rapport des participants et matériel demandé
# pour une initiation le jour même à 7h00
# Créé automatiquement lors de la publication de l'initiation
class InitiationParticipantsReportJob < ApplicationJob
  queue_as :default

  # Envoie un rapport pour une initiation spécifique
  # @param initiation_id [Integer] ID de l'initiation
  def perform(initiation_id)
    initiation = Event::Initiation.find_by(id: initiation_id)

    # Si l'initiation n'existe plus, ne rien faire
    unless initiation
      Rails.logger.warn("[InitiationParticipantsReportJob] Initiation ##{initiation_id} introuvable")
      return
    end

    # Vérifier le statut : ne pas envoyer si annulé, rejeté, ou autre statut que "published"
    unless initiation.published?
      Rails.logger.info("[InitiationParticipantsReportJob] Initiation ##{initiation_id} n'est pas publiée (statut: #{initiation.status}), email non envoyé")
      return
    end

    # Vérifier que l'initiation a bien lieu aujourd'hui (sécurité supplémentaire)
    # Bypass en dev/test : FORCE_INITIATION_REPORT=true pour envoyer même si pas le jour J
    today_start = Time.zone.now.beginning_of_day
    today_end = today_start.end_of_day
    force_report = ActiveModel::Type::Boolean.new.cast(ENV["FORCE_INITIATION_REPORT"])

    unless force_report || initiation.start_at.between?(today_start, today_end)
      Rails.logger.warn("[InitiationParticipantsReportJob] Initiation ##{initiation_id} n'a pas lieu aujourd'hui (start_at: #{initiation.start_at}), email non envoyé")
      return
    end

    # Vérifier qu'on n'a pas déjà envoyé le rapport aujourd'hui (prévention doublons)
    if initiation.participants_report_sent_at&.today?
      Rails.logger.info("[InitiationParticipantsReportJob] Rapport déjà envoyé aujourd'hui pour initiation ##{initiation_id}")
      return
    end

    begin
      # Envoi à contact@ (bureau)
      EventMailer.initiation_participants_report(initiation).deliver_later
      # Envoi à chaque bénévole inscrit (mail matériel + liste des présents)
      initiation.attendances.active.where(is_volunteer: true).includes(:user).find_each do |attendance|
        next unless attendance.user&.email.present?
        EventMailer.initiation_participants_report(initiation, recipient_email: attendance.user.email).deliver_later
      end
      # Marquer comme envoyé pour éviter les doublons (utiliser update_column pour éviter les callbacks)
      initiation.update_column(:participants_report_sent_at, Time.zone.now)
      Rails.logger.info("[InitiationParticipantsReportJob] Email de rapport enqueued pour initiation ##{initiation.id} (#{initiation.title})")
    rescue StandardError => e
      Rails.logger.error("[InitiationParticipantsReportJob] Erreur lors de l'envoi du rapport pour initiation ##{initiation.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      Sentry.capture_exception(e, extra: { initiation_id: initiation.id, initiation_title: initiation.title }) if defined?(Sentry)
    end
  end
end
