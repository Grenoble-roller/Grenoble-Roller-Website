class InitiationsController < ApplicationController
  before_action :set_initiation, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :load_supporting_data, only: [ :new, :create, :edit, :update ]

  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  def index
    # Utiliser policy_scope pour respecter les permissions Pundit
    # Les créateurs peuvent voir leurs initiations en draft, les autres voient seulement les publiées
    scoped_initiations = policy_scope(Event::Initiation.includes(:creator_user, :attendances))
    # Exclure les initiations rejetées de toutes les listes publiques (même pour modos/admins)
    # Les rejetées restent en BDD mais ne sont pas affichées dans les listes publiques
    scoped_initiations = scoped_initiations.where.not(status: "rejected")

    if can_moderate?
      # Admins/moderateurs voient les initiations non publiées (draft) mais pas les rejetées
      # Initiations à venir : 6 minicards (sans pagination)
      @upcoming_initiations = scoped_initiations.upcoming.order(:start_at).limit(6)
      
      # Initiations passées : tableau avec pagination (limité à 10 par page pour une meilleure lisibilité)
      past_scope = scoped_initiations.past.order(start_at: :desc)
      @pagy_past, @past_initiations = pagy(past_scope, page_param: :page_past, items: 10)
    else
      # Utilisateurs normaux voient seulement les initiations visibles (publiées/annulées)
      # Initiations à venir : 6 minicards (sans pagination)
      @upcoming_initiations = scoped_initiations.visible.upcoming.order(:start_at).limit(6)
      
      # Initiations passées : tableau avec pagination (limité à 10 par page pour une meilleure lisibilité)
      past_scope = scoped_initiations.visible.past.order(start_at: :desc)
      @pagy_past, @past_initiations = pagy(past_scope, page_param: :page_past, items: 10)
    end
  end

  def show
    # Pour les initiations en draft, vérifier explicitement les permissions
    # Si l'initiation n'est pas publiée et que l'utilisateur n'est pas autorisé, rediriger
    unless @initiation.published? || @initiation.canceled? || (user_signed_in? && (can_moderate? || @initiation.creator_user_id == current_user.id))
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Cette initiation n'est pas accessible." }
        format.ics { redirect_to root_path, alert: "Cette initiation n'est pas accessible." }
      end
      return
    end

    # Autoriser l'accès (lève une exception si non autorisé)
    authorize @initiation

    respond_to do |format|
      format.html do
        # @initiation déjà chargé avec includes dans set_initiation
        # Récupérer toutes les attendances de l'utilisateur (parent + enfants)
        if user_signed_in?
          @user_attendances = @initiation.attendances.where(user: current_user).includes(:child_membership)
          @user_attendance = @user_attendances.find_by(child_membership_id: nil) # Inscription parent
          @child_attendances = @user_attendances.where.not(child_membership_id: nil) # Inscriptions enfants
          # Vérifier si l'utilisateur peut s'inscrire en tant que bénévole (pas encore inscrit en tant que bénévole)
          @user_volunteer_attendance = @user_attendances.find_by(child_membership_id: nil, is_volunteer: true)
          @can_register_as_volunteer = current_user.can_be_volunteer == true && @user_volunteer_attendance.nil?

          # Charger les entrées de liste d'attente de l'utilisateur
          @user_waitlist_entries = @initiation.waitlist_entries.where(user: current_user).active.includes(:child_membership)
          @user_waitlist_entry = @user_waitlist_entries.find_by(child_membership_id: nil) # Entrée parent
          @child_waitlist_entries = @user_waitlist_entries.where.not(child_membership_id: nil) # Entrées enfants
        else
          @user_attendances = Attendance.none
          @user_attendance = nil
          @child_attendances = Attendance.none
          @user_volunteer_attendance = nil
          @can_register_as_volunteer = false

          # Charger les entrées de liste d'attente de l'utilisateur
          @user_waitlist_entries = WaitlistEntry.none
          @user_waitlist_entry = nil
          @child_waitlist_entries = WaitlistEntry.none
        end
        @can_register = can_register?
        @can_register_child = can_register_child?
      end

      format.ics do
        authenticate_user!
        authorize @initiation, :show?

        calendar = Icalendar::Calendar.new
        calendar.prodid = "-//Grenoble Roller//Initiations//FR"

        event_ical = Icalendar::Event.new
        event_ical.dtstart = Icalendar::Values::DateTime.new(@initiation.start_at)
        event_ical.dtend = Icalendar::Values::DateTime.new(@initiation.start_at + @initiation.duration_min.minutes)
        event_ical.summary = @initiation.title
        event_ical.description = @initiation.description.presence || "Initiation organisée par #{@initiation.creator_user.first_name}"

        # Location avec adresse et coordonnées GPS si disponibles
        if @initiation.location_text.present?
          location_parts = [ @initiation.location_text ]
          if @initiation.meeting_lat.present? && @initiation.meeting_lng.present?
            location_parts << "#{@initiation.meeting_lat},#{@initiation.meeting_lng}"
          end
          event_ical.location = location_parts.join(" ")
        end

        event_ical.url = initiation_url(@initiation)
        calendar.add_event(event_ical)

        send_data calendar.to_ical, type: "text/calendar", disposition: "attachment", filename: "#{@initiation.title.parameterize}.ics"
      end
    end
  end

  def new
    @initiation = Event::Initiation.new(
      creator_user: current_user,
      status: "draft",
      start_at: next_saturday_at_10_15,
      duration_min: 105, # 1h45
      max_participants: 30,
      location_text: "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble",
      level: "beginner",
      distance_km: 0,
      price_cents: 0,
      currency: "EUR"
    )
    authorize @initiation
  end

  def create
    @initiation = Event::Initiation.new(creator_user: current_user)
    authorize @initiation

    initiation_params = permitted_attributes(@initiation)
    initiation_params[:currency] = "EUR"
    initiation_params[:price_cents] = 0 # Gratuit
    initiation_params[:creator_user_id] = current_user.id

    # Seuls les modérateurs+ peuvent définir le statut à la création
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      initiation_params[:status] = "draft" # Toujours en draft à la création pour les non-modérateurs
    end

    if @initiation.update(initiation_params)
      status_message = @initiation.published? ? "Initiation créée et publiée avec succès." : "Initiation créée avec succès. Elle est en attente de validation par un modérateur."
      redirect_to initiation_path(@initiation), notice: status_message
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @initiation
  end

  def update
    authorize @initiation

    initiation_params = permitted_attributes(@initiation)
    initiation_params[:currency] = "EUR"
    initiation_params[:price_cents] = 0 # Gratuit

    # Seuls les modérateurs+ peuvent changer le statut
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      initiation_params.delete(:status)
    end

    if @initiation.update(initiation_params)
      redirect_to initiation_path(@initiation), notice: "Initiation mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @initiation
    @initiation.destroy

    redirect_to initiations_path, notice: "Initiation supprimée."
  end





  private

  def set_initiation
    # Précharger associations pour éviter N+1 queries
    @initiation = Event::Initiation.includes(:attendances, :users, :creator_user).find(params[:id])
  end

  def load_supporting_data
    # Pas de routes pour les initiations, mais on garde la méthode pour cohérence
  end

  def next_saturday_at_10_15
    next_saturday = Date.current.next_occurring(:saturday)
    Time.zone.local(next_saturday.year, next_saturday.month, next_saturday.day, 10, 15, 0)
  end

  def can_register?
    return false unless user_signed_in?
    return false if @initiation.full?
    # Permettre l'inscription si le parent n'est pas encore inscrit
    return false if @user_attendance&.persisted?

    # Les bénévoles peuvent toujours s'inscrire (même sans adhésion)
    return true if current_user.can_be_volunteer?

    # Vérifier adhésion ou essai gratuit disponible
    # Utiliser exists? (optimisé) plutôt que count > 0
    has_membership = current_user.memberships.active_now.exists?
    has_used_trial = current_user.attendances.active.where(free_trial_used: true).exists?

    has_membership || !has_used_trial
  end
  helper_method :can_register?

  def can_register_child?
    return false unless user_signed_in?
    return false if @initiation.full?
    # Vérifier qu'il y a des adhésions enfants disponibles (active, trial ou pending)
    # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
    child_memberships = current_user.memberships.where(is_child_membership: true)
      .where(status: [ Membership.statuses[:active], Membership.statuses[:trial], Membership.statuses[:pending] ])
    return false if child_memberships.empty?

    # Vérifier qu'il reste des enfants non inscrits
    registered_child_ids = @child_attendances.pluck(:child_membership_id).compact
    available_children = child_memberships.where.not(id: registered_child_ids)

    available_children.exists?
  end
  helper_method :can_register_child?

  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?

  def handle_record_not_found
    redirect_to initiations_path, alert: "Cette initiation n'existe pas ou n'est plus disponible."
  end
end
