# frozen_string_literal: true

module Initiations
  class AttendancesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_initiation

    # POST /initiations/:initiation_id/attendances
    def create
      # Stocker les paramètres dans des variables d'instance pour la policy
      @child_membership_id_for_policy = params[:child_membership_id].presence
      @is_volunteer_for_policy = params[:is_volunteer] == "1"

      # Autorisation via Pundit avec les paramètres passés à la policy
      # Créer la policy directement avec les paramètres car Pundit.policy ne les passe pas
      policy = Event::InitiationPolicy.new(current_user, @initiation,
        child_membership_id: @child_membership_id_for_policy,
        is_volunteer: @is_volunteer_for_policy
      )
      unless policy.attend?
        raise Pundit::NotAuthorizedError, query: :attend?, record: @initiation, policy: policy
      end

      child_membership_id = params[:child_membership_id].presence
      is_volunteer = params[:is_volunteer] == "1"

      # Validation des paramètres
      needs_equipment = params[:needs_equipment] == "1"
      roller_size = params[:roller_size].presence

      # Valider roller_size si needs_equipment est true
      if needs_equipment && roller_size.blank?
        redirect_to initiation_path(@initiation), alert: "Veuillez sélectionner une taille de rollers si vous avez besoin de matériel."
        return
      end

      # Valider que roller_size est dans la liste des tailles disponibles
      if needs_equipment && roller_size.present?
        unless RollerStock::SIZES.include?(roller_size)
          redirect_to initiation_path(@initiation), alert: "La taille de rollers sélectionnée n'est pas valide."
          return
        end
      end

      # Log de la tentative d'inscription
      Rails.logger.info("Tentative d'inscription - User: #{current_user.id}, Initiation: #{@initiation.id}, Child: #{child_membership_id}, Volunteer: #{is_volunteer}")
      Rails.logger.info("Params use_free_trial: #{params[:use_free_trial].inspect}, tous les params: #{params.inspect}")

      # Construction de l'attendance (hors transaction pour permettre les redirections)
      attendance = @initiation.attendances.build(user: current_user)
      attendance.status = "registered"
      # Lire les paramètres directement au niveau racine (comme EventsController)
      attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
      attendance.needs_equipment = needs_equipment
      attendance.roller_size = roller_size if needs_equipment
      attendance.child_membership_id = child_membership_id

      # Gestion bénévole (uniquement pour le parent, pas pour les enfants)
      if is_volunteer && child_membership_id.nil?
        unless current_user.can_be_volunteer?
          redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas autorisé à vous inscrire en tant que bénévole."
          return
        end
        attendance.is_volunteer = true
        # Les bénévoles n'ont pas besoin d'adhésion, on skip les vérifications
        if attendance.save
          Rails.logger.info("Inscription bénévole réussie - Attendance: #{attendance.id}, User: #{current_user.id}, Initiation: #{@initiation.id}")
          EventMailer.attendance_confirmed(attendance).deliver_later if current_user.wants_initiation_mail?
          redirect_to initiation_path(@initiation), notice: "Inscription confirmée en tant que bénévole encadrant le #{l(@initiation.start_at, format: :long)}."
        else
          Rails.logger.warn("Échec inscription bénévole - User: #{current_user.id}, Initiation: #{@initiation.id}, Errors: #{attendance.errors.full_messages.join(', ')}")
          redirect_to initiation_path(@initiation), alert: attendance.errors.full_messages.to_sentence
        end
        return
      end

      # IMPORTANT : Définir child_membership AVANT son utilisation (cohérent avec la documentation 14-flux-inscription.md:55)
      # Cela améliore la lisibilité et évite toute confusion sur la portée de la variable
      child_membership = child_membership_id.present? ? current_user.memberships.find_by(id: child_membership_id) : nil

      # Vérifier si l'utilisateur est adhérent
      # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
      # Un parent ne peut PAS utiliser l'adhésion de son enfant
      is_member = if child_membership_id.present?
        # Pour un enfant : vérifier l'adhésion enfant (active, trial ou pending)
        # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
        unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
          redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
          return
        end
        # L'enfant est considéré comme membre si l'adhésion est active ou pending (pas trial)
        child_membership&.active? || child_membership&.pending?
      else
        # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - pas d'adhésion "famille"
        current_user.memberships.active_now.where(is_child_membership: false).exists?
      end

      # Vérifier si le PARENT est adhérent (nécessaire pour les enfants trial/pending)
      # CORRECTION CRITIQUE : is_member vérifie l'enfant, pas le parent
      # Pour trial/pending, il faut vérifier directement l'adhésion du parent
      parent_is_member = current_user.memberships.active_now.exists?

      # RÈGLE MÉTIER CRITIQUE : Les essais gratuits sont NOMINATIFS
      # Chaque enfant (pending ou trial) a droit à 1 essai gratuit, indépendamment de l'adhésion du parent
      # L'essai gratuit est OBLIGATOIRE pour les enfants pending et trial, même si le parent est adhérent
      if child_membership_id.present? && (child_membership&.pending? || child_membership&.trial?)
        # Vérifier si cet enfant a déjà utilisé son essai gratuit (attendance active uniquement)
        # IMPORTANT : Exclure les attendances annulées (si annulation, l'essai gratuit redevient disponible)
        free_trial_already_used = current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?

        if free_trial_already_used
          # L'essai gratuit a déjà été utilisé : l'enfant ne peut plus s'inscrire sans adhésion active
          redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit. Une adhésion active est maintenant requise pour s'inscrire."
          return
        end

        # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif), même si le parent est adhérent
        # Vérifier que l'essai gratuit est utilisé
        use_free_trial = params[:use_free_trial] == "1" ||
                         params.select { |k, v| k.to_s.start_with?("use_free_trial_hidden") && v == "1" }.present?
        unless use_free_trial
          redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante."
          return
        end

        attendance.free_trial_used = true
      elsif child_membership_id.nil? && !is_member
        # Non-adhérent parent : vérifier si l'essai gratuit a déjà été utilisé
        # IMPORTANT : Cette vérification doit être faite AVANT de permettre l'inscription
        # même si allow_non_member_discovery est activé
        free_trial_already_used = current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

        if free_trial_already_used
          # L'essai gratuit a déjà été utilisé : l'utilisateur ne peut plus s'inscrire sans adhésion
          # même si allow_non_member_discovery est activé
          redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit. Une adhésion est maintenant requise pour continuer."
          return
        end

        # Vérifier si l'option de découverte est activée
        if @initiation.allow_non_member_discovery?
          # Option activée : vérifier qu'il reste des places découverte
          if @initiation.full_for_non_members?
            redirect_to initiation_path(@initiation), alert: "Les places pour non-adhérents sont complètes. Adhérez à l'association pour continuer."
            return
          end
          # Les non-adhérents peuvent s'inscrire dans les places découverte (pas besoin d'essai gratuit)
          # L'essai gratuit n'est utilisé que si explicitement demandé
          if params[:use_free_trial] == "1"
            # L'essai gratuit n'a pas encore été utilisé (vérifié plus haut)
            attendance.free_trial_used = true
          end
        else
          # Option non activée : comportement classique - adhésion ou essai gratuit requis
          use_free_trial = params[:use_free_trial].present? && (params[:use_free_trial] == "1" || params[:use_free_trial] == true)
          if use_free_trial
            # Vérifier essai gratuit parent (sans child_membership_id, attendance active uniquement)
            # IMPORTANT : Exclure les attendances annulées (si annulation, l'essai gratuit redevient disponible)
            if current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?
              redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
              return
            end
            attendance.free_trial_used = true
          else
            redirect_to initiation_path(@initiation), alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
            return
          end
        end
      end

      # Protection contre race condition : transaction avec lock pessimiste lors du save
      if attendance.save
        Rails.logger.info("Inscription réussie - Attendance: #{attendance.id}, User: #{current_user.id}, Initiation: #{@initiation.id}, Type: #{attendance.for_child? ? 'Enfant' : (attendance.is_volunteer ? 'Bénévole' : 'Participant')}")
        # Email de confirmation : vérifier wants_initiation_mail pour les initiations
        if current_user.wants_initiation_mail?
          EventMailer.attendance_confirmed(attendance).deliver_later
        end
        participant_name = attendance.for_child? ? attendance.participant_name : "Vous"
        type_message = attendance.is_volunteer ? "en tant que bénévole encadrant" : ""
        redirect_to initiation_path(@initiation), notice: "Inscription confirmée #{type_message} pour #{participant_name} le #{l(@initiation.start_at, format: :long)}."
      else
        Rails.logger.warn("Échec inscription - User: #{current_user.id}, Initiation: #{@initiation.id}, Errors: #{attendance.errors.full_messages.join(', ')}")
        # Améliorer les messages d'erreur
        error_message = if attendance.errors[:base].any?
          attendance.errors[:base].first
        elsif attendance.errors[:event].any?
          attendance.errors[:event].first
        elsif attendance.errors[:child_membership_id].any?
          attendance.errors[:child_membership_id].first
        elsif attendance.errors[:free_trial_used].any?
          attendance.errors[:free_trial_used].first
        else
          attendance.errors.full_messages.to_sentence
        end
        # Si l'événement est complet, proposer la liste d'attente
        if @initiation.full? && attendance.errors[:event].any?
          redirect_to initiation_path(@initiation), alert: "Cet événement est complet. #{error_message} Souhaitez-vous être ajouté(e) à la liste d'attente ?"
        else
          redirect_to initiation_path(@initiation), alert: error_message
        end
      end
    end

    # DELETE /initiations/:initiation_id/attendances (collection)
    def destroy
      authorize @initiation, :cancel_attendance?

      # Permettre de désinscrire soi-même ou un enfant spécifique
      child_membership_id = params[:child_membership_id].presence

      attendance = if child_membership_id.present?
        # Désinscrire un enfant spécifique
        @initiation.attendances.find_by(
          user: current_user,
          child_membership_id: child_membership_id
        )
      else
        # Désinscrire le parent (child_membership_id est NULL)
        @initiation.attendances.where(
          user: current_user
        ).where(child_membership_id: nil).first
      end

      if attendance
        participant_name = attendance.for_child? ? attendance.participant_name : "vous"
        wants_initiation_mail = current_user.wants_initiation_mail?
        if attendance.destroy
          # Email d'annulation : vérifier wants_initiation_mail pour les initiations
          if wants_initiation_mail && attendance.for_parent?
            EventMailer.attendance_cancelled(current_user, @initiation).deliver_later
          end
          redirect_to initiation_path(@initiation), notice: "Inscription de #{participant_name} annulée."
        else
          redirect_to initiation_path(@initiation), alert: "Impossible d'annuler cette inscription."
        end
      else
        redirect_to initiation_path(@initiation), alert: "Inscription introuvable."
      end
    end

    # PATCH /initiations/:initiation_id/attendances/toggle_reminder (collection)
    def toggle_reminder
      authenticate_user!
      authorize @initiation, :cancel_attendance? # Même permission que cancel_attendance

      # Pour les initiations, le rappel est global (1 email par compte)
      # On active/désactive le rappel pour toutes les inscriptions (parent + enfants)
      user_attendances = @initiation.attendances.where(user: current_user)

      if user_attendances.any?
        # Déterminer l'état actuel : si au moins une inscription a le rappel activé, on désactive tout
        # Sinon, on active tout
        any_reminder_active = user_attendances.any? { |a| a.wants_reminder? }
        new_reminder_state = !any_reminder_active

        # Mettre à jour toutes les inscriptions
        user_attendances.update_all(wants_reminder: new_reminder_state)

        message = new_reminder_state ? "Rappel activé pour cette initiation." : "Rappel désactivé pour cette initiation."
        redirect_to initiation_path(@initiation), notice: message
      else
        redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas inscrit(e) à cette initiation."
      end
    end

    private

    def set_initiation
      @initiation = Event::Initiation.find(params[:initiation_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to initiations_path, alert: "Initiation introuvable."
    end
  end
end
