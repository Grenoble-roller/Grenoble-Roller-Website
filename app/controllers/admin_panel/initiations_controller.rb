# frozen_string_literal: true

module AdminPanel
  class InitiationsController < BaseController
    before_action :set_initiation, only: %i[show
                                             presences update_presences
                                             convert_waitlist notify_waitlist
                                             toggle_volunteer
                                             return_material]
    before_action :authorize_initiation

    # GET /admin-panel/initiations
    def index
      authorize ::Event::Initiation, policy_class: AdminPanel::Event::InitiationPolicy

      base_scope = ::Event::Initiation
        .includes(:creator_user, :attendances, :waitlist_entries)

      # Filtres
      base_scope = base_scope.where(status: params[:status]) if params[:status].present?
      base_scope = base_scope.where(status: "published") if params[:scope] == "published"

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      base_scope = @q.result(distinct: true)

      # Séparer initiations à venir et passées
      now = Time.current

      # Si filtre "upcoming", ne garder que les à venir
      if params[:scope] == "upcoming"
        @upcoming_initiations = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc) # Prochaines d'abord, triées par date croissante
        @past_initiations = [] # Ne pas afficher les passées
      else
        # Sinon, afficher les deux sections
        @upcoming_initiations = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc) # Prochaines d'abord, triées par date croissante

        @past_initiations = base_scope
          .where("start_at <= ?", now)
          .order(start_at: :desc) # Passées ensuite, triées par date décroissante (plus récentes d'abord)
      end

      # Pour la pagination, on combine les deux listes
      # Mais on affiche séparément dans la vue
      @initiations = @upcoming_initiations + @past_initiations
    end

    # GET /admin-panel/initiations/:id
    def show
      @volunteers = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: true)
        .order(:created_at)

      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false)
        .order(:created_at)

      @waitlist_entries = @initiation.waitlist_entries
        .includes(:user, :child_membership)
        .active
        .ordered_by_position

      # Récapitulatif matériel demandé
      @equipment_requests = @initiation.attendances
        .where(needs_equipment: true)
        .where.not(roller_size: nil)
        .includes(:user, :child_membership)
        .group_by(&:roller_size)
        .transform_values { |attendances| attendances.count }
    end

    # GET /admin-panel/initiations/:id/presences
    def presences
      @volunteers = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: true)
        .where(status: %w[registered present no_show])
        .order(:created_at)

      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false)
        .where(status: %w[registered present no_show])
        .order(:created_at)
    end

    # PATCH /admin-panel/initiations/:id/update_presences
    def update_presences
      attendance_ids = params[:attendance_ids] || []
      presences = params[:presences] || {}
      is_volunteer_changes = params[:is_volunteer] || {}

      attendance_ids.each do |attendance_id|
        attendance = @initiation.attendances.find_by(id: attendance_id)
        next unless attendance

        if presences[attendance_id.to_s].present?
          attendance.update(status: presences[attendance_id.to_s])
        end

        if is_volunteer_changes[attendance_id.to_s].present?
          attendance.update(is_volunteer: is_volunteer_changes[attendance_id.to_s] == "1")
        end
      end

      redirect_to presences_admin_panel_initiation_path(@initiation),
                  notice: "Présences mises à jour avec succès"
    end

    # POST /admin-panel/initiations/:id/convert_waitlist
    def convert_waitlist
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])

      unless waitlist_entry&.notified?
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Entrée de liste d'attente non notifiée"
        return
      end

      pending_attendance = @initiation.attendances.find_by(
        user: waitlist_entry.user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: "pending"
      )

      if pending_attendance&.update(status: "registered")
        waitlist_entry.update!(status: "converted")
        WaitlistEntry.notify_next_in_queue(@initiation) if @initiation.has_available_spots?
        redirect_to admin_panel_initiation_path(@initiation),
                    notice: "Entrée convertie en inscription"
      else
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Impossible de convertir l'entrée"
      end
    end

    # POST /admin-panel/initiations/:id/notify_waitlist
    def notify_waitlist
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])

      unless waitlist_entry&.pending?
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Entrée non en attente"
        return
      end

      if waitlist_entry.notify!
        redirect_to admin_panel_initiation_path(@initiation),
                    notice: "Personne notifiée avec succès"
      else
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Impossible de notifier"
      end
    end

    # PATCH /admin-panel/initiations/:id/toggle_volunteer
    def toggle_volunteer
      attendance = @initiation.attendances.find_by(id: params[:attendance_id])

      unless attendance
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Inscription introuvable"
        return
      end

      # Vérifier si l'événement était complet avant le changement
      was_full = @initiation.full?
      new_volunteer_status = !attendance.is_volunteer
      is_adding_volunteer = new_volunteer_status # Si on passe de participant à bénévole, on libère une place

      if attendance.update(is_volunteer: new_volunteer_status)
        # Recharger l'événement pour avoir le bon comptage après le changement
        @initiation.reload

        # Si l'événement était complet et qu'on ajoute un bénévole (libère une place)
        # Alors notifier la première personne en liste d'attente
        if was_full && is_adding_volunteer && @initiation.has_available_spots?
          # Notifier la première personne en liste d'attente
          WaitlistEntry.notify_next_in_queue(@initiation, count: 1)
          Rails.logger.info("Volunteer added for attendance #{attendance.id}, notifying waitlist for initiation #{@initiation.id}")
        end

        status = attendance.is_volunteer? ? "ajouté" : "retiré"
        redirect_to admin_panel_initiation_path(@initiation),
                    notice: "Statut bénévole #{status}"
      else
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: "Impossible de modifier le statut bénévole"
      end
    end

    # POST /admin-panel/initiations/:id/return_material
    # Marque le matériel comme rendu et remet les rollers en stock
    def return_material
      authorize [ :admin_panel, @initiation ], :return_material?

      # Vérifier que l'initiation est passée
      if @initiation.start_at.present? && @initiation.start_at > Time.current
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "L'initiation n'est pas encore terminée"
        return
      end

      # Vérifier que le matériel n'a pas déjà été rendu
      if @initiation.stock_returned_at.present?
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "Le matériel a déjà été marqué comme rendu le #{l(@initiation.stock_returned_at, format: :short)}"
        return
      end

      # Remettre le stock en place
      rollers_returned = @initiation.return_roller_stock

      if rollers_returned && rollers_returned > 0
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    notice: "Matériel rendu avec succès. #{rollers_returned} roller(s) remis en stock."
      elsif rollers_returned == 0
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    notice: "Aucun matériel à remettre en stock pour cette initiation."
      else
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "Erreur lors de la remise en stock du matériel."
      end
    end

    private

    def set_initiation
      @initiation = ::Event::Initiation.find(params[:id])
    end

    def authorize_initiation
      authorize ::Event::Initiation, policy_class: AdminPanel::Event::InitiationPolicy
    end

    def initiation_params
      params.require(:event_initiation).permit(
        :title, :description, :start_at, :duration_min, :max_participants,
        :status, :location_text, :meeting_lat, :meeting_lng,
        :creator_user_id, :level, :distance_km
      )
    end
  end
end
