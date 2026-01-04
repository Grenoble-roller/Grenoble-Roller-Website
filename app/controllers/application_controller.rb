class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include TurnstileVerifiable
  include ApiResponder
  
  # Pagy 43 : La méthode pagy() est disponible directement
  # Plus besoin d'inclure Pagy::Backend (qui n'existe plus dans Pagy 43)
  # La méthode pagy() est définie comme helper dans Pagy 43

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_email_confirmation_status, if: :user_signed_in?

  rescue_from Pundit::NotAuthorizedError do |exception|
    # Pour les initiations et événements en draft, rediriger vers root même pour les utilisateurs non connectés
    if request.path.include?("/initiations/") || request.path.include?("/events/")
      record = exception.record rescue nil
      if record.is_a?(Event) && !record.published? && !record.canceled?
        redirect_to root_path, alert: "Cette ressource n'est pas accessible."
        return
      end
    end

    if user_signed_in?
      user_not_authorized(exception)
    else
      # Pour les initiations/événements, rediriger vers root au lieu de la page de connexion
      if request.path.include?("/initiations/") || request.path.include?("/events/")
        redirect_to root_path, alert: "Cette ressource n'est pas accessible."
      else
        redirect_to new_user_session_path, alert: "Vous devez être connecté pour accéder à cette page."
      end
    end
  end

  # Pagy 43 : Helper method pour la pagination dans les contrôleurs
  # Remplace Pagy::Backend qui n'existe plus dans Pagy 43
  def pagy(collection, vars = {})
    # Obtenir le nombre total d'éléments
    count = if collection.respond_to?(:count)
      collection.count
    elsif collection.respond_to?(:size)
      collection.size
    else
      collection.to_a.size
    end
    
    # Paramètres de pagination
    page = (params[:page] || vars[:page] || 1).to_i
    items = vars[:items] || Pagy.options[:items] || 25
    
    # Créer l'instance Pagy
    pagy_instance = Pagy.new(
      count: count,
      page: page,
      items: items,
      **vars.except(:items, :page)
    )
    
    # Paginer la collection
    if collection.respond_to?(:limit) && collection.respond_to?(:offset)
      # ActiveRecord::Relation
      paginated_collection = collection.limit(pagy_instance.items).offset(pagy_instance.offset)
    elsif collection.respond_to?(:[])
      # Array ou autre collection indexable
      paginated_collection = collection[pagy_instance.offset, pagy_instance.items] || []
    else
      # Fallback : convertir en array
      array = collection.to_a
      paginated_collection = array[pagy_instance.offset, pagy_instance.items] || []
    end
    
    [pagy_instance, paginated_collection]
  end

  protected

  def configure_permitted_parameters
    # Permet ces champs lors de l'inscription (4 champs : email, prénom, password, skill_level)
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name,
      :skill_level,
      :role_id
    ])

    # Permet ces champs lors de la modification du profil
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name,
      :last_name,
      :bio,
      :phone,
      :avatar_url,
      :avatar,
      :skill_level,
      :email,
      :password,
      :password_confirmation,
      :current_password,  # OBLIGATOIRE pour toute modification
      :date_of_birth,
      :address,
      :postal_code,
      :city,
      :wants_whatsapp,
      :wants_email_info
    ])
  end

  # ActiveAdmin désactivé - Tout migré vers AdminPanel (2025-01-13)
  # def active_admin_access_denied(exception)
  #   user_not_authorized(exception)
  # end

  private

  def user_not_authorized(_exception)
    if api_request?
      render json: {
        error: "Non autorisé",
        message: "Vous n'êtes pas autorisé·e à effectuer cette action."
      }, status: :forbidden
    else
      # Pour les routes d'événements, toujours rediriger vers root_path
      if request.path.include?("/events/") || request.path.include?("/initiations/")
        redirect_to root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action."
      else
        redirect_to(request.referer || root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action.")
      end
    end
  end

  helper_method :current_user_has_attendance?
  helper_method :can_moderate?

  def current_user_has_attendance?(event)
    return false unless current_user

    event.attendances.exists?(user_id: current_user.id)
  end

  def can_moderate?
    return false unless current_user

    current_user.role&.level.to_i >= 50 # Modérateur (50) ou Admin (60) ou SuperAdmin (70)
  end

  # Vérifier le statut de confirmation de l'email (gestion générale)
  def check_email_confirmation_status
    return if current_user.confirmed?
    return if skip_confirmation_check?

    # En développement et test, on peut permettre un accès limité pour les tests
    return if Rails.env.development? || Rails.env.test?

    # BLOQUER IMMÉDIATEMENT tous les utilisateurs non confirmés
    # (même pendant la période de grâce de 2 jours)
    sign_out(current_user)
    confirmation_link = view_context.link_to(
      "demandez un nouvel email de confirmation",
      new_user_confirmation_path,
      class: "alert-link"
    )
    redirect_to root_path,
                alert: "Vous devez confirmer votre adresse email pour accéder à l'application. " \
                       "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe,
                status: :forbidden
  end

  # Vérifier que l'email est confirmé pour les actions critiques
  def ensure_email_confirmed
    return unless user_signed_in?

    # En développement et en test, on ne bloque pas les actions pour faciliter les tests
    return if Rails.env.development? || Rails.env.test?

    unless current_user.confirmed?
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path,
        class: "alert-link"
      )
      redirect_to root_path,
                  alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                         "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe,
                  status: :forbidden
    end
  end

  def skip_confirmation_check?
    # Routes où confirmation n'est pas requise
    skipped_routes = %w[
      sessions#destroy
      sessions#new
      registrations#new
      confirmations#show
      confirmations#create
      passwords#new
      passwords#create
      passwords#edit
      passwords#update
    ]

    controller_action = "#{controller_name}##{action_name}"
    skipped_routes.include?(controller_action)
  end
end
