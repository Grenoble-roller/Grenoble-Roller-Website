# Job pour envoyer des rappels la veille à 19h pour les événements du lendemain
class EventReminderJob < ApplicationJob
  queue_as :default

  # Envoie des rappels pour tous les événements qui ont lieu le lendemain
  # Exécuté chaque jour à 19h, envoie des rappels pour les événements du jour suivant
  # Groupe les attendances par utilisateur et événement pour éviter les emails multiples
  def perform
    # Définir le début et la fin de demain (00:00:00 à 23:59:59)
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day
    tomorrow_end = tomorrow_start.end_of_day

    # Trouver les événements publiés qui ont lieu demain (dans toute la journée)
    events = Event.published
                  .upcoming
                  .where(start_at: tomorrow_start..tomorrow_end)

    events.find_each do |event|
      is_initiation = event.is_a?(Event::Initiation)

      # Récupérer toutes les attendances actives qui doivent recevoir un rappel
      pending_attendances = event.attendances.active
                                  .where(wants_reminder: true)
                                  .where(reminder_sent_at: nil)
                                  .includes(:user, :event, :child_membership)

      # Grouper les attendances par utilisateur (parent)
      # Un parent peut avoir plusieurs attendances pour le même événement (lui-même + enfants)
      attendances_by_user = pending_attendances.group_by(&:user_id)

      attendances_by_user.each do |user_id, attendances|
        user = attendances.first.user
        next unless user&.email.present?

        # Pour les initiations, vérifier aussi la préférence globale wants_initiation_mail
        if is_initiation && !user.wants_initiation_mail?
          next # Skip si l'utilisateur a désactivé les emails d'initiations
        end

        # Envoyer UN SEUL email avec toutes les attendances de cet utilisateur pour cet événement
        EventMailer.event_reminder(user, event, attendances).deliver_later

        # Mettre à jour le flag reminder_sent_at pour toutes les attendances
        # (utiliser update_column pour éviter les callbacks)
        attendances.each do |attendance|
          attendance.update_column(:reminder_sent_at, Time.zone.now)
        end
      end
    end
  end
end
