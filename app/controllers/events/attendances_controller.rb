# frozen_string_literal: true

module Events
  class AttendancesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event
    before_action :ensure_email_confirmed, only: [ :create ] # Exiger confirmation pour s'inscrire à un événement

    # POST /events/:event_id/attendances
    def create
      authorize @event, :attend?

      child_membership_id = params[:child_membership_id].presence

      # Si c'est pour un enfant, vérifier qu'il n'est pas déjà inscrit
      if child_membership_id.present?
        existing_attendance = @event.attendances.find_by(
          user: current_user,
          child_membership_id: child_membership_id
        )
        if existing_attendance
          child_name = Membership.find_by(id: child_membership_id)&.child_full_name || "cet enfant"
          redirect_to @event, notice: "#{child_name} est déjà inscrit(e) à cet événement."
          return
        end
      else
        # Si c'est pour le parent, vérifier qu'il n'est pas déjà inscrit
        existing_attendance = @event.attendances.find_by(
          user: current_user,
          child_membership_id: nil
        )
        if existing_attendance
          redirect_to @event, notice: "Vous êtes déjà inscrit(e) à cet événement."
          return
        end
      end

      attendance = @event.attendances.build(user: current_user)
      attendance.status = "registered"
      # Accepter wants_reminder depuis les params (formulaire ou paramètre direct)
      attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
      attendance.child_membership_id = child_membership_id

      # Pour les événements normaux (randos) : ouverts à tous, aucune restriction d'adhésion
      # Vérifier seulement que l'adhésion enfant appartient à l'utilisateur si un enfant est inscrit
      if child_membership_id.present?
        child_membership = current_user.memberships.find_by(id: child_membership_id, is_child_membership: true)
        unless child_membership
          redirect_to @event, alert: "Cette adhésion enfant ne vous appartient pas."
          return
        end
      end
      # Pour le parent : aucune restriction, ouvert à tous

      if attendance.save
        EventMailer.attendance_confirmed(attendance).deliver_later
        participant_name = attendance.for_child? ? attendance.participant_name : "Vous"
        event_date = l(@event.start_at, format: :event_long, locale: :fr)
        redirect_to @event, notice: "Inscription confirmée pour #{participant_name} ! À bientôt le #{event_date}."
      else
        # Si l'événement est complet, proposer la liste d'attente
        if @event.full? && attendance.errors[:event].any?
          redirect_to @event, alert: "Cet événement est complet. #{attendance.errors.full_messages.to_sentence} Souhaitez-vous être ajouté(e) à la liste d'attente ?"
        else
          redirect_to @event, alert: attendance.errors.full_messages.to_sentence
        end
      end
    end

    # DELETE /events/:event_id/attendances (collection)
    def destroy
      authenticate_user!
      authorize @event, :cancel_attendance?

      # Permettre de désinscrire soi-même ou un enfant spécifique
      child_membership_id = params[:child_membership_id].presence

      attendance = if child_membership_id.present?
        # Désinscrire un enfant spécifique
        @event.attendances.find_by(
          user: current_user,
          child_membership_id: child_membership_id
        )
      else
        # Désinscrire le parent (child_membership_id est NULL)
        @event.attendances.where(
          user: current_user
        ).where(child_membership_id: nil).first
      end

      if attendance
        participant_name = attendance.for_child? ? attendance.participant_name : "vous"
        wants_events_mail = current_user.wants_events_mail?
        if attendance.destroy
          # Notifier la prochaine personne en liste d'attente si une place se libère
          WaitlistEntry.notify_next_in_queue(@event) if @event.full?
          if wants_events_mail && attendance.for_parent?
            EventMailer.attendance_cancelled(current_user, @event).deliver_later
          end
          redirect_to @event, notice: "Inscription de #{participant_name} annulée."
        else
          redirect_to @event, alert: "Impossible d'annuler cette inscription."
        end
      else
        redirect_to @event, alert: "Inscription introuvable."
      end
    end

    # PATCH /events/:event_id/attendances/toggle_reminder (collection)
    def toggle_reminder
      authenticate_user!
      authorize @event, :cancel_attendance? # Même permission que cancel_attendance

      # Pour les événements, le rappel est global (1 email par compte)
      # On active/désactive le rappel pour toutes les inscriptions (parent + enfants)
      user_attendances = @event.attendances.where(user: current_user)

      if user_attendances.any?
        # Déterminer l'état actuel : si au moins une inscription a le rappel activé, on désactive tout
        # Sinon, on active tout
        any_reminder_active = user_attendances.any? { |a| a.wants_reminder? }
        new_reminder_state = !any_reminder_active

        # Mettre à jour toutes les inscriptions
        user_attendances.update_all(wants_reminder: new_reminder_state)

        message = new_reminder_state ? "Rappel activé pour cet événement." : "Rappel désactivé pour cet événement."
        redirect_to @event, notice: message
      else
        redirect_to @event, alert: "Vous n'êtes pas inscrit(e) à cet événement."
      end
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to events_path, alert: "Événement introuvable."
    end
  end
end
