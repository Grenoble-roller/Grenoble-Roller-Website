class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy loop_routes reject]
  before_action :authenticate_user!, except: %i[index show]
  before_action :load_supporting_data, only: %i[new create edit update]

  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  def index
    # Exclure les initiations (qui ont leur propre contrôleur)
    scoped_events = policy_scope(Event.not_initiations.includes(:route, :creator_user))
    # Exclure les événements rejetés de toutes les listes publiques (même pour modos/admins)
    # Les rejetés restent en BDD mais ne sont pas affichés dans les listes publiques
    scoped_events = scoped_events.where.not(status: "rejected")

    # Appliquer les filtres
    scoped_events = apply_filters(scoped_events)

    if can_moderate?
      # Admins/moderateurs voient les événements non publiés (draft) mais pas les rejetés
      # Événements à venir : 6 minicards (sans pagination)
      @upcoming_events = scoped_events.upcoming.order(:start_at).limit(6)
      
      # Événements passés : tableau avec pagination (limité à 10 par page pour une meilleure lisibilité)
      past_scope = scoped_events.past.order(start_at: :desc)
      @pagy_past, @past_events = pagy(past_scope, page_param: :page_past, items: 10)
    else
      # Utilisateurs normaux voient seulement les événements visibles (publiés/annulés)
      # Événements à venir : 6 minicards (sans pagination)
      @upcoming_events = scoped_events.visible.upcoming.order(:start_at).limit(6)
      
      # Événements passés : tableau avec pagination (limité à 10 par page pour une meilleure lisibilité)
      past_scope = scoped_events.visible.past.order(start_at: :desc)
      @pagy_past, @past_events = pagy(past_scope, page_param: :page_past, items: 10)
    end

    # Charger les données pour les filtres
    @routes = Route.order(:name)
    @levels = [
      ["Débutant", "beginner"],
      ["Intermédiaire", "intermediate"],
      ["Confirmé", "advanced"],
      ["Tous niveaux", "all_levels"]
    ]
  end

  def show
    respond_to do |format|
      format.html do
        # Vérifier les permissions avant de continuer
        unless policy(@event).show?
          redirect_to root_path, alert: "Cet événement n'est pas accessible."
          return
        end
        authorize @event

        # Rediriger si l'événement n'est pas visible (publié ou annulé) et que l'utilisateur n'est pas modo+ ou créateur
        unless @event.published? || @event.canceled? || can_moderate? || @event.creator_user_id == current_user&.id
          redirect_to events_path, alert: "Cet événement n'est pas encore publié."
          return
        end
        # Récupérer toutes les attendances de l'utilisateur (parent + enfants)
        if user_signed_in?
          @user_attendances = @event.attendances.where(user: current_user).includes(:child_membership)
          @user_attendance = @user_attendances.find_by(child_membership_id: nil) # Inscription parent
          @child_attendances = @user_attendances.where.not(child_membership_id: nil) # Inscriptions enfants

          # Charger les entrées de liste d'attente de l'utilisateur
          @user_waitlist_entries = @event.waitlist_entries.where(user: current_user).active.includes(:child_membership)
          @user_waitlist_entry = @user_waitlist_entries.find_by(child_membership_id: nil) # Entrée parent
          @child_waitlist_entries = @user_waitlist_entries.where.not(child_membership_id: nil) # Entrées enfants
        else
          @user_attendances = Attendance.none
          @user_attendance = nil
          @child_attendances = Attendance.none
          @user_waitlist_entries = WaitlistEntry.none
          @user_waitlist_entry = nil
          @child_waitlist_entries = WaitlistEntry.none
        end
        @can_register_child = can_register_child?
      end

      format.ics do
        authenticate_user!
        # Pour les événements en draft, vérifier explicitement les permissions avant authorize
        unless @event.published? || @event.canceled? || (user_signed_in? && (can_moderate? || @event.creator_user_id == current_user.id))
          redirect_to root_path, alert: "Cet événement n'est pas accessible."
          return
        end
        authorize @event, :show?

        calendar = Icalendar::Calendar.new
        calendar.prodid = "-//Grenoble Roller//Events//FR"

        event_ical = Icalendar::Event.new
        event_ical.dtstart = Icalendar::Values::DateTime.new(@event.start_at)
        event_ical.dtend = Icalendar::Values::DateTime.new(@event.start_at + @event.duration_min.minutes)
        event_ical.summary = @event.title
        event_ical.description = @event.description.presence || "Événement organisé par #{@event.creator_user.first_name}"

        # Location avec adresse et coordonnées GPS si disponibles
        if @event.has_gps_coordinates?
          # Format iCal : adresse avec coordonnées GPS dans le champ location
          event_ical.location = "#{@event.location_text} (#{@event.meeting_lat},#{@event.meeting_lng})"
          # Ajout du champ GEO pour les coordonnées GPS (standard iCal RFC 5545)
          # Format: [latitude, longitude]
          event_ical.geo = [ @event.meeting_lat, @event.meeting_lng ]
        else
          event_ical.location = @event.location_text
        end

        event_ical.url = event_url(@event)
        event_ical.uid = "event-#{@event.id}@grenobleroller.fr"
        event_ical.last_modified = @event.updated_at
        event_ical.created = @event.created_at
        event_ical.organizer = Icalendar::Values::CalAddress.new("mailto:noreply@grenobleroller.fr", cn: "Grenoble Roller")

        calendar.add_event(event_ical)
        calendar.publish

        send_data calendar.to_ical,
                  filename: "#{@event.title.parameterize}.ics",
                  type: "text/calendar; charset=utf-8",
                  disposition: "attachment"
      end
    end
  end

  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?

  def can_register_child?
    return false unless user_signed_in?
    return false if @event.full?
    # Vérifier qu'il y a des adhésions enfants actives disponibles
    child_memberships = current_user.memberships.active_now.where(is_child_membership: true)
    return false if child_memberships.empty?

    # Vérifier qu'il reste des enfants non inscrits
    # Si @child_attendances n'est pas défini (pas encore d'inscription), on peut inscrire n'importe quel enfant
    if @child_attendances.nil? || @child_attendances.empty?
      return child_memberships.exists?
    end

    registered_child_ids = @child_attendances.pluck(:child_membership_id).compact
    available_children = child_memberships.where.not(id: registered_child_ids)

    available_children.exists?
  end
  helper_method :can_register_child?

  def new
    @event = current_user.created_events.build(
      status: "draft", # Toujours en brouillon à la création (en attente de validation)
      start_at: Time.zone.now.change(min: 0),
      duration_min: 60,
      max_participants: 0, # 0 = illimité par défaut
      currency: "EUR" # Toujours EUR
    )

    # Vérifier explicitement les permissions avant authorize pour rediriger correctement
    unless policy(@event).new?
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à créer un événement."
      return
    end

    authorize @event
  end

  def create
    @event = current_user.created_events.build
    authorize @event

    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = "EUR"
    # Toujours en draft à la création (en attente de validation par un modérateur)
    event_params[:status] = "draft"
    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    # Initialiser loops_count à 1 si non défini
    event_params[:loops_count] ||= 1

    # Gérer les parcours par boucle
    loop_routes_params = params[:event_loop_routes] || {}

    if @event.update(event_params)
      # Sauvegarder les parcours par boucle
      save_loop_routes(@event, loop_routes_params)

      redirect_to @event, notice: "Événement créé avec succès. Il est en attente de validation par un modérateur."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = "EUR"

    # Seuls les modérateurs+ peuvent changer le statut
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      event_params.delete(:status) # Retirer le statut des params si l'utilisateur n'est pas modo+
    end

    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    # Initialiser loops_count à 1 si non défini
    event_params[:loops_count] ||= 1

    # Gérer les parcours par boucle
    loop_routes_params = params[:event_loop_routes] || {}

    if @event.update(event_params)
      # Sauvegarder les parcours par boucle
      save_loop_routes(@event, loop_routes_params)

      redirect_to @event, notice: "Événement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to events_path, notice: "Événement supprimé."
  end

  def reject
    authorize @event, :reject?

    if @event.update(status: :rejected)
      # Envoyer un email au créateur pour le notifier du refus
      EventMailer.event_rejected(@event).deliver_later
      redirect_to events_path, notice: "L'événement a été refusé et le créateur a été notifié par email."
    else
      redirect_to @event, alert: "Impossible de refuser cet événement."
    end
  end





  # Retourner les parcours par boucle en JSON (pour le formulaire)
  def loop_routes
    authorize @event, :show?

    loop_routes_data = @event.event_loop_routes.where("loop_number > 1").order(:loop_number).map do |elr|
      {
        loop_number: elr.loop_number,
        route_id: elr.route_id,
        distance_km: elr.distance_km
      }
    end

    render json: loop_routes_data
  end

  private

  def set_event
    @event = Event.includes(:route, :creator_user, event_loop_routes: :route).find(params[:id])
    # Charger l'attendance de l'utilisateur connecté si présent
    @user_attendance = current_user&.attendances&.find_by(event: @event) if user_signed_in?
  end

  def load_supporting_data
    @routes = Route.order(:name)
  end

  # Appliquer les filtres depuis les paramètres
  def apply_filters(events)
    # Filtre par route
    if params[:route_id].present?
      events = events.where(route_id: params[:route_id])
    end

    # Filtre par niveau
    if params[:level].present? && Event.level.values.include?(params[:level])
      events = events.where(level: params[:level])
    end

    events
  end

  # Sauvegarder les parcours par boucle
  def save_loop_routes(event, loop_routes_params)
    # Supprimer les anciens parcours par boucle
    event.event_loop_routes.destroy_all

    # Si plusieurs boucles, sauvegarder le parcours principal pour la boucle 1
    if event.loops_count && event.loops_count > 1 && event.route_id.present? && event.distance_km.present?
      event.event_loop_routes.create!(
        loop_number: 1,
        route_id: event.route_id,
        distance_km: event.distance_km
      )
    end

    # Créer les parcours pour les boucles supplémentaires (2, 3, etc.)
    loop_routes_params.each do |loop_number_str, route_data|
      next unless route_data[:route_id].present? && route_data[:distance_km].present?

      loop_number = loop_number_str.to_i
      route_id = route_data[:route_id].to_i
      distance_km = route_data[:distance_km].to_f

      # Ignorer la boucle 1 (déjà gérée avec le parcours principal)
      next if loop_number < 2 || route_id < 1 || distance_km < 0.1

      event.event_loop_routes.create!(
        loop_number: loop_number,
        route_id: route_id,
        distance_km: distance_km
      )
    end
  end

  def handle_record_not_found
    redirect_to events_path, alert: "Cet événement n'existe pas ou n'est plus disponible."
  end
end
