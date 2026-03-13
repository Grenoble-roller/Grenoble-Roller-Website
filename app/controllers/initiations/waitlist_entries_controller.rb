# frozen_string_literal: true

module Initiations
  class WaitlistEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_initiation, only: [ :create, :destroy ] # set_initiation seulement pour les routes collection

    # POST /initiations/:initiation_id/waitlist_entries
    def create
      authorize @initiation, :join_waitlist? # Utiliser la policy spécifique pour la liste d'attente

      child_membership_id = params[:child_membership_id].presence
      needs_equipment = params[:needs_equipment] == "1"
      roller_size = params[:roller_size].presence
      wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
      use_free_trial = params[:use_free_trial] == "1"

      # Vérifier les conditions d'essai gratuit pour les enfants
      # RÈGLE MÉTIER : Les essais gratuits sont NOMINATIFS - chaque enfant a droit à 1 essai gratuit
      # L'essai gratuit est OBLIGATOIRE pour les enfants pending et trial, peu importe si le parent est adhérent
      if child_membership_id.present?
        child_membership = current_user.memberships.find_by(id: child_membership_id, is_child_membership: true)

        unless child_membership
          redirect_to initiation_path(@initiation), alert: "Cette adhésion enfant ne vous appartient pas."
          return
        end

        # Pour un enfant avec statut trial OU pending : essai gratuit OBLIGATOIRE (nominatif)
        # Chaque enfant a droit à son propre essai gratuit, indépendamment de l'adhésion du parent
        if child_membership.trial? || child_membership.pending?
          # Essai gratuit OBLIGATOIRE pour cet enfant
          unless use_free_trial
            redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
            return
          end

          # Vérifier si cet enfant a déjà utilisé son essai gratuit (nominatif)
          if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
            redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit."
            return
          end
        end

        # Si use_free_trial est coché, vérifier que l'essai gratuit n'a pas déjà été utilisé
        if use_free_trial
          if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
            redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit."
            return
          end
        end
      else
        # Pour le parent : vérifier si le PARENT a déjà utilisé son essai gratuit (nominatif)
        if use_free_trial
          if current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?
            redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
            return
          end
        end
      end

      if needs_equipment && roller_size.blank?
        redirect_to initiation_path(@initiation), alert: "Veuillez sélectionner une taille de rollers si vous avez besoin de matériel."
        return
      end
      if needs_equipment && roller_size.present?
        unless RollerStock::SIZES.include?(roller_size)
          redirect_to initiation_path(@initiation), alert: "La taille de rollers sélectionnée n'est pas valide."
          return
        end
      end

      # Créer l'entrée de waitlist avec gestion des erreurs
      waitlist_entry = WaitlistEntry.new(
        user: current_user,
        event: @initiation,
        child_membership_id: child_membership_id,
        needs_equipment: needs_equipment,
        roller_size: roller_size,
        wants_reminder: wants_reminder,
        use_free_trial: use_free_trial
      )

      # Valider avant d'essayer de sauvegarder
      unless waitlist_entry.valid?
        error_messages = waitlist_entry.errors.full_messages.join(", ")
        redirect_to initiation_path(@initiation), alert: "Impossible d'ajouter à la liste d'attente : #{error_messages}"
        return
      end

      # Utiliser la méthode de classe pour créer l'entrée (gère les vérifications de doublons, etc.)
      waitlist_entry = WaitlistEntry.add_to_waitlist(
        current_user,
        @initiation,
        child_membership_id: child_membership_id,
        needs_equipment: needs_equipment,
        roller_size: roller_size,
        wants_reminder: wants_reminder,
        use_free_trial: use_free_trial
      )

      if waitlist_entry
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to initiation_path(@initiation), notice: "#{participant_name} avez été ajouté(e) à la liste d'attente. Vous serez notifié(e) par email si une place se libère."
      else
        # Vérifier les raisons possibles de l'échec
        # Utiliser !full? au lieu de has_available_spots? pour être cohérent avec la validation du modèle
        if !@initiation.full?
          redirect_to initiation_path(@initiation), alert: "L'événement n'est pas complet. Vous pouvez vous inscrire directement."
        elsif WaitlistEntry.exists?(
          user: current_user,
          event: @initiation,
          child_membership_id: child_membership_id,
          status: [ "pending", "notified" ]
        )
          redirect_to initiation_path(@initiation), alert: "Vous êtes déjà en liste d'attente pour cet événement."
        elsif current_user.attendances.exists?(
          event: @initiation,
          child_membership_id: child_membership_id
        )
          redirect_to initiation_path(@initiation), alert: "Vous êtes déjà inscrit(e) à cet événement."
        else
          redirect_to initiation_path(@initiation), alert: "Impossible d'ajouter à la liste d'attente. Vérifiez que l'événement est complet et que vous n'êtes pas déjà inscrit(e) ou en liste d'attente."
        end
      end
    end

    # DELETE /waitlist_entries/:id (shallow)
    def destroy
      child_membership_id = params[:child_membership_id].presence

      waitlist_entry = if params[:id].present?
        # Si on a un ID (shallow route), chercher directement
        WaitlistEntry.find_by_hashid(params[:id])
      else
        # Sinon, chercher par child_membership_id (collection route)
        # Dans ce cas, on a besoin de @initiation qui est défini par set_initiation
        @initiation.waitlist_entries.find_by(
          user: current_user,
          child_membership_id: child_membership_id,
          status: [ "pending", "notified" ]
        )
      end

      unless waitlist_entry && waitlist_entry.user == current_user
        event = waitlist_entry&.event || @initiation
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Vous n'êtes pas en liste d'attente pour cet événement."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :leave_waitlist?

      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      event = waitlist_entry.event
      redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
      redirect_to redirect_path, notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    end

    # POST /waitlist_entries/:id/convert_to_attendance (shallow route)
    def convert_to_attendance
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :convert_waitlist_to_attendance?

      # Vérifier que l'inscription "pending" existe toujours
      pending_attendance = waitlist_entry.event.attendances.find_by(
        user: current_user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: "pending"
      )

      unless pending_attendance
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
        return
      end

      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_initiation_mail?
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # POST /waitlist_entries/:id/refuse (shallow route)
    def refuse
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :refuse_waitlist?

      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Vous avez refusé la place pour #{participant_name}. Vous avez été retiré(e) de l'événement et de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/confirm (shallow route)
    # Accepte soit un token (via email) soit une authentification classique
    def confirm
      waitlist_entry = find_waitlist_entry_for_action

      unless waitlist_entry
        redirect_to root_path, alert: "Lien invalide ou expiré. Veuillez vous connecter pour confirmer votre place."
        return
      end

      # Vérifier que l'entrée est bien notifiée et le token valide
      unless waitlist_entry.notified? && waitlist_entry.token_valid?
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Ce lien n'est plus valide. La place a peut-être déjà été confirmée ou le délai de 24h est expiré."
        return
      end

      # Autoriser l'action sur l'événement (skip Pundit si token valide)
      unless skip_authorization_for_token? || (user_signed_in? && policy(waitlist_entry.event).convert_waitlist_to_attendance?)
        redirect_to root_path, alert: "Vous n'êtes pas autorisé à effectuer cette action."
        return
      end

      # Effectuer l'action
      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)

        # Si non connecté, rediriger vers connexion avec message
        unless user_signed_in?
          store_location_for(:user, redirect_path)
          redirect_to new_user_session_path, notice: "Inscription confirmée pour #{participant_name} ! Veuillez vous connecter pour voir les détails."
          return
        end

        redirect_to redirect_path, notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/decline (shallow route)
    # Accepte soit un token (via email) soit une authentification classique
    def decline
      waitlist_entry = find_waitlist_entry_for_action

      unless waitlist_entry
        redirect_to root_path, alert: "Lien invalide ou expiré. Veuillez vous connecter pour refuser la place."
        return
      end

      # Vérifier que l'entrée est bien notifiée et le token valide
      unless waitlist_entry.notified? && waitlist_entry.token_valid?
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Ce lien n'est plus valide. La place a peut-être déjà été confirmée ou le délai de 24h est expiré."
        return
      end

      # Autoriser l'action sur l'événement (skip Pundit si token valide)
      unless skip_authorization_for_token? || (user_signed_in? && policy(waitlist_entry.event).refuse_waitlist?)
        redirect_to root_path, alert: "Vous n'êtes pas autorisé à effectuer cette action."
        return
      end

      # Effectuer l'action
      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)

        # Si non connecté, rediriger vers connexion avec message
        unless user_signed_in?
          store_location_for(:user, redirect_path)
          redirect_to new_user_session_path, notice: "Vous avez refusé la place pour #{participant_name}. Veuillez vous connecter pour voir les détails."
          return
        end

        redirect_to redirect_path, notice: "Vous avez refusé la place pour #{participant_name}. Vous avez été retiré(e) de l'événement et de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    private

    def set_initiation
      @initiation = Event::Initiation.find(params[:initiation_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to initiations_path, alert: "Initiation introuvable."
    end

    # Trouve le waitlist_entry soit via token (email) soit via hashid (authentifié)
    def find_waitlist_entry_for_action
      # Priorité 1 : Token depuis email (sécurisé avec expiration)
      if params[:token].present?
        waitlist_entry = WaitlistEntry.find_by_confirmation_token(params[:token])
        return waitlist_entry if waitlist_entry&.token_valid?
      end

      # Priorité 2 : Hashid si utilisateur authentifié
      if user_signed_in?
        waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
        waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

        # Vérifier que c'est bien l'utilisateur connecté
        if waitlist_entry && waitlist_entry.user == current_user
          return waitlist_entry
        end
      end

      nil
    end

    # Skip authorization si on utilise un token valide (le token garantit l'authenticité)
    def skip_authorization_for_token?
      params[:token].present? && WaitlistEntry.find_by_confirmation_token(params[:token])&.token_valid?
    end
  end
end
