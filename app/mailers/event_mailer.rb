class EventMailer < ApplicationMailer
  include EventsHelper
  # Email de confirmation d'inscription à un événement
  def attendance_confirmed(attendance)
    @attendance = attendance
    @event = attendance.event
    @user = attendance.user
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "✅ Inscription confirmée - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "✅ Inscription confirmée : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de confirmation de désinscription d'un événement
  def attendance_cancelled(user, event)
    @user = user
    @event = event
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "❌ Désinscription confirmée - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "❌ Désinscription confirmée : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de rappel 24h avant l'événement
  # Accepte plusieurs attendances pour le même utilisateur et événement (cas des initiations avec enfants)
  # @param user [User] L'utilisateur (parent) qui recevra l'email
  # @param event [Event] L'événement concerné
  # @param attendances [Array<Attendance>] Liste des attendances de cet utilisateur pour cet événement
  def event_reminder(user, event, attendances)
    @user = user
    @event = event
    @attendances = Array(attendances) # S'assurer que c'est un tableau
    @is_initiation = @event.is_a?(Event::Initiation)

    # Si plusieurs participants (parent + enfants), adapter le sujet
    participant_count = @attendances.count
    subject = if @is_initiation
      if participant_count > 1
        "📅 Rappel : Initiation roller demain samedi #{l(@event.start_at, format: :day_month, locale: :fr)} (#{participant_count} participants)"
      else
        "📅 Rappel : Initiation roller demain samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
      end
    else
      "📅 Rappel : #{@event.title} demain !"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de notification d'annulation d'un événement à tous les inscrits et bénévoles
  # Accepte plusieurs attendances pour le même utilisateur et événement (cas des initiations avec enfants)
  # @param user [User] L'utilisateur (parent) qui recevra l'email
  # @param event [Event] L'événement annulé
  # @param attendances [Array<Attendance>] Liste des attendances de cet utilisateur pour cet événement
  def event_cancelled(user, event, attendances)
    @user = user
    @event = event
    @attendances = Array(attendances) # S'assurer que c'est un tableau
    @is_initiation = @event.is_a?(Event::Initiation)

    # Si plusieurs participants (parent + enfants), adapter le sujet
    participant_count = @attendances.count
    subject = if @is_initiation
      if participant_count > 1
        "⚠️ Événement annulé - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)} (#{participant_count} participants)"
      else
        "⚠️ Événement annulé - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
      end
    else
      "⚠️ Événement annulé : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de notification de refus d'un événement au créateur
  def event_rejected(event)
    @event = event
    @creator = event.creator_user
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "❌ Votre initiation a été refusée"
    else
      "❌ Votre événement \"#{@event.title}\" a été refusé"
    end

    mail(
      to: @creator.email,
      subject: subject
    )
  end

  # Email de notification qu'une place est disponible en liste d'attente
  def waitlist_spot_available(waitlist_entry)
    # IMPORTANT : Recharger l'objet pour s'assurer que notified_at est à jour
    # (évite les problèmes si le job est exécuté avant que la transaction soit commitée)
    waitlist_entry.reload if waitlist_entry.persisted?

    @waitlist_entry = waitlist_entry
    @event = waitlist_entry.event
    @user = waitlist_entry.user
    @is_initiation = @event.is_a?(Event::Initiation)
    @participant_name = waitlist_entry.participant_name

    # Générer le token sécurisé pour les liens d'acceptation/refus (valide 24h)
    @confirmation_token = waitlist_entry.confirmation_token

    # Vérifier que notified_at est présent avant de calculer expiration_time
    if waitlist_entry.notified_at.present?
      @expiration_time = waitlist_entry.notified_at + 24.hours # 24 heures pour confirmer
    else
      Rails.logger.error("WaitlistEntry #{waitlist_entry.id} has nil notified_at in waitlist_spot_available mailer")
      @expiration_time = 24.hours.from_now # Fallback si notified_at est nil
    end

    subject = if @is_initiation
      "🎉 Place disponible - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "🎉 Place disponible : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de rapport des participants et matériel pour une initiation (envoyé à 7h le jour de l'initiation)
  # @param initiation [Event::Initiation]
  # @param recipient_email [String, nil] Si présent, envoi à cette adresse (bénévole) ; sinon à contact@grenoble-roller.org
  def initiation_participants_report(initiation, recipient_email: nil)
    @initiation = initiation

    # Récupérer tous les participants actifs (non bénévoles, non annulés)
    @participants = initiation.attendances
                              .active
                              .participants
                              .includes(:user, :child_membership)
                              .order(:created_at)

    # Filtrer uniquement ceux qui demandent du matériel
    @participants_with_equipment = @participants.select { |a| a.needs_equipment? && a.roller_size.present? }

    to_address = recipient_email.presence || "contact@grenoble-roller.org"

    mail(
      to: to_address,
      subject: "📋 Rapport participants - Initiation #{l(@initiation.start_at, format: :day_month, locale: :fr)}"
    )
  end
end
