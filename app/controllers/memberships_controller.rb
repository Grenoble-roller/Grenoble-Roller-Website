class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ]
  before_action :set_membership, only: [ :show, :edit, :update, :destroy, :upgrade, :renew ]
  before_action :ensure_parent_profile_complete_for_child, only: [ :new ]

  def index
    @memberships = current_user.memberships.includes(:payment, :tshirt_variant).order(created_at: :desc)

    # Variables pour la section "Nouvelle adhésion"
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates

    # Vérifier s'il y a une adhésion personnelle en cours (pending ou active) pour cette saison
    current_season = Membership.current_season_name
    existing_memberships = current_user.memberships.personal.where(season: current_season)
    @pending_membership = existing_memberships.find { |m| m.status == "pending" }
    @active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
  end

  def new
    type = params[:type] # "adult", "teen", "children", ou nil (choix initial)
    children_count = params[:count]&.to_i

    # Si pas de type, rediriger vers index (la page principale avec les options)
    unless type
      redirect_to memberships_path
      return
    end

    # Si renouvellement depuis une adhésion expirée (pour enfants)
    if type == "child" && params[:renew_from].present?
      old_membership = current_user.memberships.find_by(id: params[:renew_from])
      if old_membership && old_membership.is_child_membership? && old_membership.expired?
        @old_membership = old_membership
        # Pré-remplir les informations depuis l'ancienne adhésion
        # Note: on ne pré-remplit PAS with_tshirt pour permettre de choisir un nouveau T-shirt
        @membership = Membership.new(
          is_child_membership: true,
          child_first_name: old_membership.child_first_name,
          child_last_name: old_membership.child_last_name,
          child_date_of_birth: old_membership.child_date_of_birth,
          category: old_membership.category,
          with_tshirt: false,
          tshirt_size: nil,
          tshirt_qty: 0
        )
      end
    end

    # Si renouvellement depuis une adhésion expirée (pour adultes)
    if type == "adult" && params[:renew_from].present?
      old_membership = current_user.memberships.find_by(id: params[:renew_from])
      if old_membership && !old_membership.is_child_membership? && old_membership.expired?
        @old_membership = old_membership
        # Pré-remplir les informations depuis l'ancienne adhésion
        # Note: Pour les adultes, les données (first_name, last_name, date_of_birth, etc.) sont dans User
        # On crée un objet Membership avec seulement la catégorie de l'ancienne adhésion
        # Les données du User seront utilisées directement dans la vue via @user
        # (harmonisation avec logique enfant : @membership pour catégorie, @user pour données personnelles)
        @membership = Membership.new(
          is_child_membership: false,
          category: old_membership.category,
          with_tshirt: false,
          tshirt_size: nil,
          tshirt_qty: 0
        )
      end
    end

    # Vérifier si l'utilisateur a déjà une adhésion personnelle active ou pending (sauf pour enfants)
    if %w[adult teen].include?(type)
      current_season = Membership.current_season_name
      existing_memberships = current_user.memberships.personal.where(season: current_season)

      # Vérifier adhésion active (protection contre end_date nil)
      active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
      if active_membership
        redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
        return
      end

      # Vérifier adhésion pending
      pending_membership = existing_memberships.find { |m| m.status == "pending" }
      if pending_membership
        redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
        return
      end

      # Vérifier adhésion expired avec paiement abandoned
      expired_with_abandoned = existing_memberships.find do |m|
        m.expired? && m.payment&.provider == "helloasso" && m.payment.status == "abandoned"
      end
      if expired_with_abandoned
        redirect_to membership_path(expired_with_abandoned),
                    alert: "Vous avez une adhésion expirée avec un paiement abandonné pour cette saison. " \
                           "Vous pouvez réessayer le paiement depuis la page de l'adhésion, ou contacter un membre du bureau si vous rencontrez des difficultés."
        return
      end
    end

    @type = type
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates

    # S'assurer que les dates sont valides (protection contre les valeurs nil)
    unless @start_date.present? && @end_date.present?
      Rails.logger.error("[MembershipsController#new] Erreur: start_date ou end_date est nil. start_date=#{@start_date.inspect}, end_date=#{@end_date.inspect}")
      redirect_to memberships_path, alert: "Erreur lors du calcul des dates de saison. Veuillez réessayer ou contacter le support."
      return
    end

    @categories = get_categories
    @user = current_user

    if type == "teen"
      # Pour les ados, on permet de saisir la date de naissance dans le formulaire si absente
      # La vérification d'âge se fera lors de la création de l'adhésion
    elsif type == "adult"
      # Pour les adultes, on permet de saisir la date de naissance dans le formulaire si absente
      # La vérification d'âge se fera lors de la création de l'adhésion
      # Initialiser @membership si ce n'est pas déjà fait (pour les nouveaux adhérents)
      @membership ||= Membership.new(is_child_membership: false)
    end

    # Rendre la vue appropriée
    case type
    when "adult"
      render :adult_form
    when "teen"
      render :teen_form
    when "child"
      # Formulaire pour un seul enfant (simplifié)
      @season = Membership.current_season_name
      @start_date, @end_date = Membership.current_season_dates

      # S'assurer que les dates sont valides (protection contre les valeurs nil)
      unless @start_date.present? && @end_date.present?
        Rails.logger.error("[MembershipsController#new] Erreur: start_date ou end_date est nil pour child. start_date=#{@start_date.inspect}, end_date=#{@end_date.inspect}")
        redirect_to memberships_path, alert: "Erreur lors du calcul des dates de saison. Veuillez réessayer ou contacter le support."
        return
      end

      @categories = {
        standard: {
          name: "Cotisation Adhérent Grenoble Roller",
          description: "Je souhaite être membre bienfaiteur ou actif de l'association. Accès aux initiations pour la saison inclus.",
          price_cents: 1000
        },
        with_ffrs: {
          name: "Cotisation Adhérent Grenoble Roller + Licence FFRS",
          description: "Je souhaite être membre bienfaiteur ou actif de l'association. Je souhaite également prendre la licence de la FFRS (Loisir ou Compétition).",
          price_cents: 5655
        }
      }
      @user = current_user

      # Vérifier si l'enfant a déjà utilisé son essai gratuit (pour le renouvellement ou si l'enfant existe déjà)
      @child_has_used_trial = false
      if @old_membership
        # Cet enfant (même identité que l'ancienne adhésion) a-t-il déjà utilisé son essai gratuit ?
        child_ids = current_user.memberships.children
          .where(
            child_first_name: @old_membership.child_first_name,
            child_last_name: @old_membership.child_last_name,
            child_date_of_birth: @old_membership.child_date_of_birth
          )
          .select(:id)
        @child_has_used_trial = current_user.attendances.active
          .where(child_membership_id: child_ids, free_trial_used: true)
          .exists?
      elsif @membership&.child_first_name.present? && @membership&.child_last_name.present? && @membership&.child_date_of_birth.present?
        # Pour un enfant pré-rempli, vérifier s'il existe déjà une adhésion trial utilisée
        existing_trial_membership = current_user.memberships.children
          .where(child_first_name: @membership.child_first_name,
                 child_last_name: @membership.child_last_name,
                 child_date_of_birth: @membership.child_date_of_birth,
                 status: :trial)
          .first
        if existing_trial_membership
          @child_has_used_trial = current_user.attendances.where(
            child_membership_id: existing_trial_membership.id,
            free_trial_used: true
          ).exists?
        end
      end

      render :child_form
    end
  end

  def check_age_and_redirect
    # Vérifier d'abord si l'utilisateur a déjà une adhésion personnelle active ou pending
    current_season = Membership.current_season_name
    existing_memberships = current_user.memberships.personal.where(season: current_season)

    # Vérifier adhésion active (protection contre end_date nil)
    active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
    if active_membership
      # Message adapté avec informations sur l'adhésion
      flash[:info] = "Vous avez déjà une adhésion active pour la saison #{current_season}. Elle est valable jusqu'au #{I18n.l(active_membership.end_date, format: :long)}."
      flash[:show_membership_modal] = true
      redirect_to membership_path(active_membership)
      return
    end

    # Vérifier adhésion pending
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      # Message adapté pour adhésion en attente
      flash[:warning] = "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
      flash[:show_membership_modal] = true
      redirect_to membership_path(pending_membership)
      return
    end

    # Si pas de date de naissance, permettre de continuer (sera renseignée dans le formulaire)
    if current_user.date_of_birth.blank?
      # Rediriger directement vers le formulaire adulte
      redirect_to new_membership_path(type: "adult")
      return
    end

    # Calculer l'âge si date de naissance présente
    age = current_user.age

    # Rediriger selon l'âge
    if age < 16
      flash[:alert] = "Pour les personnes de moins de 16 ans, veuillez contacter un membre du bureau de l'association pour procéder à l'adhésion. #{helpers.link_to('Contactez-nous', contact_path, class: 'alert-link')} pour plus d'informations.".html_safe
      redirect_to new_membership_path
      nil
    elsif age >= 16 && age < 18
      # Rediriger vers le formulaire ado
      redirect_to new_membership_path(type: "teen")
      nil
    else
      # Rediriger directement vers le formulaire adulte
      redirect_to new_membership_path(type: "adult")
      nil
    end
  end

  def create
    # Renouvellement d'une adhésion enfant expirée (avec formulaire)
    if params[:renew_from].present?
      old_membership = current_user.memberships.find_by(id: params[:renew_from])
      if old_membership && old_membership.is_child_membership? && old_membership.expired?
        # Bloquer si ce même enfant a déjà une adhésion pour la saison courante (avant d'appeler renew_child_membership_from_form)
        current_season = Membership.current_season_name
        existing_membership = current_user.memberships.children
          .where(season: current_season)
          .where(status: [ Membership.statuses[:active], Membership.statuses[:pending], Membership.statuses[:trial] ])
          .find_by(
            child_first_name: old_membership.child_first_name,
            child_last_name: old_membership.child_last_name,
            child_date_of_birth: old_membership.child_date_of_birth
          )
        if existing_membership
          redirect_to membership_path(existing_membership), notice: "Une adhésion existe déjà pour #{old_membership.child_full_name} pour cette saison."
          return
        end
        membership_params = params[:membership] || params
        # Utiliser la catégorie du formulaire (peut être différente de l'ancienne)
        renew_child_membership_from_form(old_membership, membership_params)
        return
      elsif old_membership && old_membership.is_child_membership? && !old_membership.expired?
        redirect_to memberships_path, alert: "Cette adhésion n'est pas expirée."
        return
      end
    end

    # Vérifier si c'est un essai gratuit (statut trial) - pas de paiement nécessaire
    if params[:create_trial] == "1"
      membership_params = params[:membership] || params
      if membership_params[:is_child_membership] == "true" || membership_params[:is_child_membership] == true
        create_child_membership_single
        return
      end
    end

    # Vérifier si c'est un paiement sans HelloAsso
    if params[:payment_method] == "cash_check" || params[:payment_method] == "without_payment"
      create_without_payment
      return
    end

    # Détecter le type depuis les paramètres
    membership_params = params[:membership] || params

    if membership_params[:is_child_membership] == "true" || membership_params[:is_child_membership] == true
      # Création d'un enfant unique
      create_child_membership_single
    elsif membership_params[:type] == "teen"
      create_teen_membership
    else
      create_adult_membership
    end
  end

  # Créer une adhésion sans paiement HelloAsso (espèces/chèques)
  def create_without_payment
    membership_params = params[:membership] || params

    if membership_params[:is_child_membership] == "true" || membership_params[:is_child_membership] == true
      create_child_membership_without_payment
    elsif membership_params[:type] == "teen"
      create_teen_membership_without_payment
    else
      create_adult_membership_without_payment
    end
  end

  # Création groupée d'enfants (plusieurs enfants, un seul paiement)
  def show
    @membership = @membership || current_user.memberships.find(params[:id])
  end


  # Modifier une adhésion enfant (pending uniquement)
  def edit
    # Seules les adhésions enfants en attente peuvent être modifiées
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être modifiée."
      return
    end

    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @user = current_user
    render :edit_child_form
  end

  # Mettre à jour une adhésion (uniquement enfants pending)
  def update
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être modifiée."
      return
    end

    membership_params = params[:membership] || params

    # Reconstruire la date de naissance
    if membership_params[:child_date_of_birth].blank?
      day = membership_params[:child_date_of_birth_day]
      month = membership_params[:child_date_of_birth_month]
      year = membership_params[:child_date_of_birth_year]

      if day.present? && month.present? && year.present?
        begin
          membership_params[:child_date_of_birth] = Date.new(year.to_i, month.to_i, day.to_i).to_s
        rescue ArgumentError => e
          redirect_to edit_membership_path(@membership), alert: "Date de naissance invalide."
          return
        end
      end
    end

    # Calculer l'âge de l'enfant
    child_date_of_birth = Date.parse(membership_params[:child_date_of_birth]) rescue nil
    if child_date_of_birth.blank?
      redirect_to edit_membership_path(@membership), alert: "Date de naissance obligatoire."
      return
    end

    child_age = ((Date.today - child_date_of_birth) / 365.25).floor

    if child_age < 6
      redirect_to edit_membership_path(@membership), alert: "L'adhésion n'est pas possible pour les enfants de moins de 6 ans."
      return
    end

    if child_age >= 18
      redirect_to edit_membership_path(@membership), alert: "L'enfant a 18 ans ou plus, il doit adhérer seul."
      return
    end

    # Mettre à jour l'adhésion
    @membership.update!(
      category: membership_params[:category],
      child_first_name: membership_params[:child_first_name],
      child_last_name: membership_params[:child_last_name],
      child_date_of_birth: child_date_of_birth,
      amount_cents: Membership.price_for_category(membership_params[:category]),
      is_minor: child_age < 18,
      parent_authorization: child_age < 16 ? (membership_params[:parent_authorization] == "1") : false,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      rgpd_consent: membership_params[:rgpd_consent] == "1",
      legal_notices_accepted: membership_params[:legal_notices_accepted] == "1",
      ffrs_data_sharing_consent: membership_params[:ffrs_data_sharing_consent] == "1"
    )

    # Vérifier les réponses au questionnaire de santé (9 questions)
    has_health_issue = false
    all_answered_no = true
    all_answered = true
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      if answer.blank?
        all_answered = false
        all_answered_no = false
      elsif answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer == "no"
        # Réponse NON, continue
      end
    end

    # Traiter Standard et FFRS de la même manière : questionnaire obligatoire, certificat médical jamais obligatoire
    # Vérifier que toutes les questions sont répondues
    unless all_answered
      redirect_to edit_membership_path(@membership), alert: "Le questionnaire de santé est obligatoire. Veuillez répondre à toutes les questions."
      return
    end

    # Même logique pour Standard et FFRS : juste mettre le statut selon les réponses
    @membership.health_questionnaire_status = has_health_issue ? "medical_required" : "ok"

    # Mettre à jour les réponses du questionnaire
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      @membership.send("health_q#{i}=", answer) if answer.present?
    end

    # Attacher le certificat médical si fourni
    if membership_params[:medical_certificate].present?
      @membership.medical_certificate.attach(membership_params[:medical_certificate])
    end

    # Sauvegarder les modifications
    @membership.save!

    redirect_to memberships_path, notice: "Adhésion de #{@membership.child_full_name} mise à jour avec succès."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la mise à jour : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to edit_membership_path(@membership), alert: "Erreur lors de la mise à jour : #{e.message}"
  end

  # Supprimer une adhésion (uniquement enfants pending)
  def destroy
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être supprimée."
      return
    end

    child_name = @membership.child_full_name

    # Vérifier si l'adhésion est référencée par des participations (attendances)
    if Attendance.where(child_membership_id: @membership.id).exists?
      redirect_to membership_path(@membership),
        alert: "Cette adhésion ne peut pas être supprimée car #{child_name} a déjà participé à des événements ou initiations. Veuillez contacter le support si vous souhaitez la supprimer."
      return
    end

    # Supprimer le paiement associé s'il existe et n'est pas lié à d'autres adhésions
    if @membership.payment
      payment = @membership.payment
      # Si le paiement est lié à plusieurs adhésions, ne pas le supprimer
      if payment.memberships.count > 1
        @membership.update!(payment: nil)
      else
        payment.destroy
      end
    end

    @membership.destroy

    redirect_to memberships_path, notice: "Adhésion de #{child_name} supprimée avec succès."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la suppression : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to memberships_path, alert: "Erreur lors de la suppression : #{e.message}"
  end

  # Convertir un essai gratuit (trial) en adhésion payante (pending)
  def upgrade
    unless @membership.is_child_membership? && @membership.trial?
      redirect_to memberships_path, alert: "Cette adhésion ne peut pas être convertie."
      return
    end

    # Définir les dates de saison (le montant est déjà défini lors de la création avec la catégorie)
    start_date, end_date = Membership.current_season_dates

    # Mettre à jour l'adhésion : trial → pending (le montant est déjà correct)
    @membership.update!(
      status: :pending,
      start_date: start_date,
      end_date: end_date
      # amount_cents n'est pas modifié car il était déjà défini à la création
    )

    redirect_to membership_path(@membership), notice: "L'essai gratuit de #{@membership.child_full_name} a été converti en adhésion. Vous pouvez maintenant procéder au paiement."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la conversion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to memberships_path, alert: "Erreur lors de la conversion : #{e.message}"
  end

  # Renouvellement d'une adhésion enfant expirée (avec formulaire pour choisir la catégorie)
  def renew
    old_membership = @membership

    unless old_membership.is_child_membership? && old_membership.expired?
      redirect_to membership_path(old_membership), alert: "Cette adhésion ne peut pas être renouvelée."
      return
    end

    # Rediriger vers le formulaire de création avec renew_from
    redirect_to new_membership_path(type: "child", renew_from: old_membership.id)
  end

  private

  def set_membership
    @membership = current_user.memberships.find(params[:id])
  end

  # Empêcher l'accès au formulaire enfant si le profil parent n'est pas complet
  # Règle : 7 champs obligatoires sur le parent pour créer un enfant :
  # - first_name, last_name, phone
  # - address, postal_code, city
  # - date_of_birth
  def ensure_parent_profile_complete_for_child
    return unless params[:type] == "child"

    return if current_user.child_profile_complete_for_membership?

    missing_keys = current_user.missing_child_profile_fields_for_membership

    labels = {
      first_name: "prénom",
      last_name: "nom",
      phone: "numéro de téléphone",
      address: "adresse postale",
      postal_code: "code postal",
      city: "ville",
      date_of_birth: "date de naissance"
    }

    missing_labels = missing_keys.map { |key| labels[key] || key.to_s.humanize }.join(", ")

    flash[:alert] = "Pour ajouter un enfant, veuillez d'abord compléter votre profil parent : #{missing_labels}."
    redirect_to edit_user_registration_path
  end

  def get_categories
    {
      standard: {
        name: "Cotisation Adhérent Grenoble Roller",
        price_cents: 1000,
        description: "Je souhaite être membre bienfaiteur ou actif de l'association. Accès aux initiations pour la saison inclus."
      },
      with_ffrs: {
        name: "Cotisation Adhérent Grenoble Roller + Licence FFRS",
        price_cents: 5655,
        description: "Je souhaite être membre bienfaiteur ou actif de l'association. Je souhaite également prendre la licence de la FFRS (Loisir). Plus d'informations sur le site de la FFRS"
      }
    }
  end


  def create_adult_membership
    membership_params = params[:membership] || params
    category = membership_params[:category]

    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    current_season = Membership.current_season_name

    # Vérifier les adhésions existantes pour cette saison
    existing_memberships = current_user.memberships.personal.where(season: current_season)

    # Vérifier si une adhésion active existe
    active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    # Vérifier si une adhésion pending existe
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates

    # S'assurer que les dates sont valides (protection contre les valeurs nil)
    unless start_date.present? && end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: start_date ou end_date est nil. start_date=#{start_date.inspect}, end_date=#{end_date.inspect}")
      redirect_to new_membership_path, alert: "Erreur lors du calcul des dates de saison. Veuillez réessayer ou contacter le support."
      return
    end

    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User (même si certains champs sont vides, on met à jour ceux qui sont fournis)
    user_update_params = {}

    # Mettre à jour les champs fournis
    user_update_params[:first_name] = membership_params[:first_name] if membership_params[:first_name].present?
    user_update_params[:last_name] = membership_params[:last_name] if membership_params[:last_name].present?
    user_update_params[:phone] = membership_params[:phone] if membership_params[:phone].present?
    user_update_params[:email] = membership_params[:email] if membership_params[:email].present?
    user_update_params[:address] = membership_params[:address] if membership_params[:address].present?
    user_update_params[:city] = membership_params[:city] if membership_params[:city].present?
    user_update_params[:postal_code] = membership_params[:postal_code] if membership_params[:postal_code].present?

    # Toujours mettre à jour la date de naissance si fournie (même si les autres champs ne le sont pas)
    if membership_params[:date_of_birth].present?
      user_update_params[:date_of_birth] = membership_params[:date_of_birth]
    end

    # Ajouter les préférences email si fournies
    if params[:user]
      user_update_params[:wants_initiation_mail] = params[:user][:wants_initiation_mail] == "1" if params[:user][:wants_initiation_mail].present?
      user_update_params[:wants_events_mail] = params[:user][:wants_events_mail] == "1" if params[:user][:wants_events_mail].present?
    end

    # Mettre à jour l'utilisateur si au moins un paramètre est fourni
    if user_update_params.any?
      current_user.update!(user_update_params)
    end

    # Vérifier l'âge après mise à jour (ou utiliser l'âge existant)
    if current_user.date_of_birth.blank?
      redirect_to new_membership_path(type: "adult"), alert: "La date de naissance est obligatoire pour adhérer."
      return
    end

    # Validation stricte : bloquer les moins de 16 ans
    user_age = current_user.age
    if user_age < 16
      redirect_to new_membership_path(type: "adult"), alert: "L'adhésion adulte n'est pas possible pour les personnes de moins de 16 ans. Veuillez contacter un membre du bureau de l'association pour procéder à l'adhésion. #{helpers.link_to('Contactez-nous', contact_path, class: 'alert-link')} pour plus d'informations.".html_safe
      return
    end

    # À partir de 16 ans, l'adhésion est possible (les parents peuvent être prévenus pour les 16-17 ans)

    # Vérifier les réponses au questionnaire de santé (9 questions)
    has_health_issue = false
    all_answered_no = true
    all_answered = true
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      if answer.blank?
        all_answered = false
        all_answered_no = false
      elsif answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer == "no"
        # Réponse NON, continue
      end
    end

    # Traiter Standard et FFRS de la même manière : questionnaire obligatoire, certificat médical jamais obligatoire
    # Vérifier que toutes les questions sont répondues
    unless all_answered
      redirect_to new_membership_path(type: "adult"), alert: "Le questionnaire de santé est obligatoire. Veuillez répondre à toutes les questions."
      return
    end

    # Même logique pour Standard et FFRS : juste mettre le statut selon les réponses
    membership_params[:health_questionnaire_status] = has_health_issue ? "medical_required" : "ok"

    # Adhésion simple uniquement (plus d'option T-shirt)
    with_tshirt = false
    tshirt_size = nil
    tshirt_qty = 0

    # Préparer les attributs du questionnaire de santé
    health_attrs = {
      health_questionnaire_status: membership_params[:health_questionnaire_status] || "ok"
    }
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      health_attrs["health_q#{i}"] = answer if answer.present?
    end

    # S'assurer que end_date est défini avant la création (double vérification)
    unless end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: end_date est nil juste avant la création de l'adhésion")
      redirect_to new_membership_path, alert: "Erreur lors du calcul de la date de fin de saison. Veuillez réessayer ou contacter le support."
      return
    end

    # Créer l'adhésion en pending
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: false,
      is_minor: current_user.is_minor?,
      tshirt_variant_id: nil,
      tshirt_price_cents: nil,
      # Adhésion simple uniquement (plus d'option T-shirt)
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0,
      # Questionnaire de santé
      **health_attrs
    )

    # Attacher le certificat médical si fourni
    if membership_params[:medical_certificate].present?
      membership.medical_certificate.attach(membership_params[:medical_certificate])
    end

    # Validation déjà effectuée avant création, pas besoin de re-vérifier ici

    # Créer le paiement HelloAsso
    begin
      checkout_result = HelloassoService.membership_checkout_redirect_url(
        membership,
        back_url: new_membership_url,
        error_url: membership_url(membership),
        return_url: membership_url(membership)
      )

      unless checkout_result && checkout_result.is_a?(Hash) && checkout_result[:redirect_url]
        Rails.logger.error("[MembershipsController] Échec: checkout_result invalide ou nil: #{checkout_result.inspect}")
        Rails.logger.error("[MembershipsController] Membership ##{membership.id} sera détruite")
        membership.destroy
        redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez vérifier les logs ou contacter le support si le problème persiste."
        return
      end

      redirect_url = checkout_result[:redirect_url]
      checkout_id = checkout_result[:checkout_id]

      # Créer le Payment avec l'ID du checkout-intent
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id ? checkout_id.to_s : nil,
        status: "pending",
        amount_cents: membership.total_amount_cents,
        currency: "EUR"
      )
      membership.update!(payment: payment, provider_order_id: checkout_id ? checkout_id.to_s : nil)

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[MembershipsController] Erreur lors de la création du checkout-intent : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso : #{e.message}. Veuillez réessayer ou contacter le support."
      nil
    end
  rescue ActiveRecord::RecordNotUnique => e
    # Gérer l'erreur de contrainte unique (adhésion déjà existante pour cette saison)
    Rails.logger.error("[MembershipsController] Erreur de contrainte unique lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.personal.find_by(season: current_season)

    if existing_membership
      if existing_membership.expired? && existing_membership.payment&.status == "abandoned"
        redirect_to membership_path(existing_membership),
                    alert: "Vous avez déjà une adhésion pour cette saison avec un paiement abandonné. " \
                           "Vous pouvez réessayer le paiement depuis la page de l'adhésion, ou contacter un membre du bureau pour obtenir de l'aide."
      else
        redirect_to membership_path(existing_membership),
                    alert: "Une adhésion existe déjà pour cette saison. " \
                           "Si vous rencontrez un problème, veuillez contacter un membre du bureau."
      end
    else
      redirect_to new_membership_path,
                  alert: "Une erreur est survenue lors de la création de l'adhésion. " \
                         "Il semble qu'une adhésion existe déjà pour cette saison. " \
                         "Veuillez contacter un membre du bureau si le problème persiste."
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Vérifier si c'est une erreur de contrainte unique PostgreSQL
    if e.message.include?("duplicate key") || e.message.include?("UniqueViolation")
      current_season = Membership.current_season_name
      existing_membership = current_user.memberships.personal.find_by(season: current_season)

      if existing_membership
        if existing_membership.expired? && existing_membership.payment&.status == "abandoned"
          redirect_to membership_path(existing_membership),
                      alert: "Vous avez déjà une adhésion pour cette saison avec un paiement abandonné. " \
                             "Vous pouvez réessayer le paiement depuis la page de l'adhésion, ou contacter un membre du bureau pour obtenir de l'aide."
        else
          redirect_to membership_path(existing_membership),
                      alert: "Une adhésion existe déjà pour cette saison. " \
                             "Si vous rencontrez un problème, veuillez contacter un membre du bureau."
        end
      else
        redirect_to new_membership_path,
                    alert: "Une erreur est survenue lors de la création de l'adhésion. " \
                           "Il semble qu'une adhésion existe déjà pour cette saison. " \
                           "Veuillez contacter un membre du bureau si le problème persiste."
      end
    else
      redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
    end
  end

  def create_teen_membership
    membership_params = params[:membership] || params
    category = membership_params[:category]

    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    current_season = Membership.current_season_name

    # Vérifier les adhésions existantes pour cette saison
    existing_memberships = current_user.memberships.personal.where(season: current_season)

    # Vérifier si une adhésion active existe
    active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    # Vérifier si une adhésion pending existe
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    # Vérifier adhésion expired avec paiement abandoned
    expired_with_abandoned = existing_memberships.find do |m|
      m.expired? && m.payment&.provider == "helloasso" && m.payment.status == "abandoned"
    end
    if expired_with_abandoned
      redirect_to membership_path(expired_with_abandoned),
                  alert: "Vous avez une adhésion expirée avec un paiement abandonné pour cette saison. " \
                         "Vous pouvez réessayer le paiement depuis la page de l'adhésion, ou contacter un membre du bureau si vous rencontrez des difficultés."
      return
    end

    start_date, end_date = Membership.current_season_dates

    # S'assurer que les dates sont valides (protection contre les valeurs nil)
    unless start_date.present? && end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: start_date ou end_date est nil. start_date=#{start_date.inspect}, end_date=#{end_date.inspect}")
      redirect_to new_membership_path, alert: "Erreur lors du calcul des dates de saison. Veuillez réessayer ou contacter le support."
      return
    end

    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User (même si certains champs sont vides, on met à jour ceux qui sont fournis)
    user_update_params = {}

    # Mettre à jour les champs fournis
    user_update_params[:first_name] = membership_params[:first_name] if membership_params[:first_name].present?
    user_update_params[:last_name] = membership_params[:last_name] if membership_params[:last_name].present?
    user_update_params[:phone] = membership_params[:phone] if membership_params[:phone].present?
    user_update_params[:email] = membership_params[:email] if membership_params[:email].present?
    user_update_params[:address] = membership_params[:address] if membership_params[:address].present?
    user_update_params[:city] = membership_params[:city] if membership_params[:city].present?
    user_update_params[:postal_code] = membership_params[:postal_code] if membership_params[:postal_code].present?

    # Toujours mettre à jour la date de naissance si fournie (même si les autres champs ne le sont pas)
    if membership_params[:date_of_birth].present?
      user_update_params[:date_of_birth] = membership_params[:date_of_birth]
    end

    # Ajouter les préférences email si fournies (anciennes versions pour compatibilité)
    user_update_params[:wants_whatsapp] = membership_params[:wants_whatsapp] == "1" if membership_params[:wants_whatsapp].present?
    user_update_params[:wants_email_info] = membership_params[:wants_email_info] == "1" if membership_params[:wants_email_info].present?

    # Ajouter les préférences email si fournies (nouvelles versions)
    if params[:user]
      user_update_params[:wants_initiation_mail] = params[:user][:wants_initiation_mail] == "1" if params[:user][:wants_initiation_mail].present?
      user_update_params[:wants_events_mail] = params[:user][:wants_events_mail] == "1" if params[:user][:wants_events_mail].present?
    end

    # Mettre à jour l'utilisateur si au moins un paramètre est fourni
    if user_update_params.any?
      current_user.update!(user_update_params)
    end

    # Vérifier l'âge après mise à jour (ou utiliser l'âge existant)
    if current_user.date_of_birth.blank?
      redirect_to new_membership_path(type: "teen"), alert: "La date de naissance est obligatoire pour adhérer."
      return
    end

    age = current_user.age
    if age < 16
      redirect_to new_membership_path(type: "teen"), alert: "Vous devez avoir au moins 16 ans pour adhérer seul."
      return
    elsif age >= 18
      redirect_to new_membership_path(type: "adult"), alert: "Vous avez 18 ans ou plus, veuillez choisir l'option 'Adulte'."
      return
    end

    # S'assurer que end_date est défini avant la création (double vérification)
    unless end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: end_date est nil juste avant la création de l'adhésion")
      redirect_to new_membership_path, alert: "Erreur lors du calcul de la date de fin de saison. Veuillez réessayer ou contacter le support."
      return
    end

    # Créer l'adhésion en pending
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: false,
      is_minor: true, # Les ados sont mineurs
      tshirt_variant_id: nil,
      tshirt_price_cents: nil,
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0,
      parent_email: membership_params[:parent_email],
      parent_name: membership_params[:parent_name] || "#{current_user.first_name} #{current_user.last_name}",
      parent_phone: membership_params[:parent_phone] || current_user.phone
    )

    # Créer le paiement HelloAsso
    begin
      checkout_result = HelloassoService.membership_checkout_redirect_url(
        membership,
        back_url: new_membership_url,
        error_url: membership_url(membership),
        return_url: membership_url(membership)
      )

      unless checkout_result && checkout_result.is_a?(Hash) && checkout_result[:redirect_url]
        Rails.logger.error("[MembershipsController] Échec: checkout_result invalide ou nil: #{checkout_result.inspect}")
        Rails.logger.error("[MembershipsController] Membership ##{membership.id} sera détruite")
        membership.destroy
        redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez vérifier les logs ou contacter le support si le problème persiste."
        return
      end

      redirect_url = checkout_result[:redirect_url]
      checkout_id = checkout_result[:checkout_id]

      # Créer le Payment avec l'ID du checkout-intent
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id ? checkout_id.to_s : nil,
        status: "pending",
        amount_cents: membership.total_amount_cents,
        currency: "EUR"
      )
      membership.update!(payment: payment, provider_order_id: checkout_id ? checkout_id.to_s : nil)

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[MembershipsController] Erreur lors de la création du checkout-intent : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso : #{e.message}. Veuillez réessayer ou contacter le support."
      nil
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end

  # Renouvellement depuis le formulaire (avec catégorie choisie)
  def renew_child_membership_from_form(old_membership, membership_params)
    # Récupérer la catégorie depuis le formulaire (peut être différente de l'ancienne)
    category = membership_params[:category]

    unless Membership.categories.key?(category)
      redirect_to new_membership_path(type: "child", renew_from: old_membership.id), alert: "Catégorie d'adhésion invalide."
      return
    end

    # Vérifier l'âge de l'enfant
    child_age = old_membership.child_age

    if child_age >= 18
      redirect_to memberships_path, alert: "L'enfant a maintenant 18 ans ou plus, il doit adhérer avec son propre compte."
      return
    end

    if child_age < 6
      redirect_to memberships_path, alert: "L'adhésion n'est pas possible pour les enfants de moins de 6 ans."
      return
    end

    current_season = Membership.current_season_name
    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Vérifier qu'il n'y a pas déjà une adhésion pour cette saison
    # On vérifie pour le même enfant (même nom, prénom, date de naissance)
    # Récupérer toutes les adhésions enfants pour cette saison avec les statuts actifs
    current_season_memberships = current_user.memberships.children
      .where(season: current_season)
      .where(status: [ Membership.statuses[:active], Membership.statuses[:pending], Membership.statuses[:trial] ])
      .to_a

    existing_membership = current_season_memberships.find do |m|
      m.child_first_name == old_membership.child_first_name &&
      m.child_last_name == old_membership.child_last_name &&
      m.child_date_of_birth == old_membership.child_date_of_birth
    end

    if existing_membership
      redirect_to membership_path(existing_membership), notice: "Une adhésion existe déjà pour #{old_membership.child_full_name} pour cette saison."
      return
    end

    # Créer la nouvelle adhésion avec les mêmes informations (mais catégorie depuis le formulaire)
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: true,
      child_first_name: old_membership.child_first_name,
      child_last_name: old_membership.child_last_name,
      child_date_of_birth: old_membership.child_date_of_birth,
      is_minor: child_age < 18,
      parent_authorization: child_age < 16,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      parent_name: "#{current_user.first_name} #{current_user.last_name}",
      parent_email: current_user.email,
      parent_phone: current_user.phone,
      with_tshirt: false,
      tshirt_qty: 0,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: category == "with_ffrs",
      health_questionnaire_status: "ok",
      # Copier les réponses au questionnaire de santé de l'ancienne adhésion
      health_q1: old_membership.health_q1,
      health_q2: old_membership.health_q2,
      health_q3: old_membership.health_q3,
      health_q4: old_membership.health_q4,
      health_q5: old_membership.health_q5,
      health_q6: old_membership.health_q6,
      health_q7: old_membership.health_q7,
      health_q8: old_membership.health_q8,
      health_q9: old_membership.health_q9
    )

    # Copier le certificat médical si présent
    if old_membership.medical_certificate.attached?
      old_membership.medical_certificate.open do |file|
        membership.medical_certificate.attach(
          io: file,
          filename: old_membership.medical_certificate.filename.to_s,
          content_type: old_membership.medical_certificate.content_type
        )
      end
    end

    redirect_to membership_path(membership), notice: "L'adhésion de #{membership.child_full_name} a été renouvelée avec succès. Vous pouvez maintenant procéder au paiement."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors du renouvellement : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path(type: "child", renew_from: old_membership.id), alert: "Erreur lors du renouvellement : #{e.message}"
  end

  def create_child_membership_single
    # Création d'un enfant unique - redirection vers /memberships pour afficher l'enfant créé
    membership_params = params[:membership] || params

    membership = create_child_membership_from_params(membership_params, 0)

    if membership.persisted?
      # Message différent selon le statut
      if membership.trial?
        redirect_to memberships_path, notice: "#{membership.child_full_name} a été ajouté avec succès. Vous pouvez maintenant utiliser l'essai gratuit pour une initiation."
      else
        redirect_to memberships_path, notice: "#{membership.child_full_name} a été ajouté avec succès. Vous pouvez maintenant procéder au paiement."
      end
    else
      redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{membership.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[MembershipsController] Erreur de validation : #{e.record.errors.full_messages.join(', ')}")
    redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    error_message = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.join(", ") : e.message
    redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{error_message}"
  end

  def create_child_membership_from_params(child_params, index)
    # Normaliser les clés (convertir en symbol si nécessaire)
    child_params = child_params.symbolize_keys if child_params.is_a?(Hash) && child_params.keys.first.is_a?(String)

    category = child_params[:category]
    # Adhésion simple uniquement (plus d'option T-shirt)

    unless Membership.categories.key?(category)
      return Membership.new.tap { |m| m.errors.add(:category, "invalide") }
    end

    # Validation des champs enfant
    child_first_name = child_params[:child_first_name]
    child_last_name = child_params[:child_last_name]

    # Reconstruire la date à partir des 3 champs (jour, mois, année) ou utiliser le champ caché
    child_date_of_birth = child_params[:child_date_of_birth]
    if child_date_of_birth.blank?
      # Essayer de reconstruire depuis les champs séparés
      day = child_params[:child_date_of_birth_day]
      month = child_params[:child_date_of_birth_month]
      year = child_params[:child_date_of_birth_year]

      if day.present? && month.present? && year.present?
        begin
          child_date_of_birth = Date.new(year.to_i, month.to_i, day.to_i)
        rescue ArgumentError => e
          return Membership.new.tap { |m| m.errors.add(:base, "Date de naissance invalide") }
        end
      end
    else
      child_date_of_birth = Date.parse(child_date_of_birth) rescue nil
    end

    if child_first_name.blank? || child_last_name.blank? || child_date_of_birth.blank?
      return Membership.new.tap { |m| m.errors.add(:base, "Tous les champs obligatoires doivent être remplis") }
    end

    # Calculer l'âge de l'enfant
    child_age = ((Date.today - child_date_of_birth) / 365.25).floor

    if child_age < 6
      return Membership.new.tap { |m| m.errors.add(:child_date_of_birth, "L'adhésion n'est pas possible pour les enfants de moins de 6 ans") }
    end

    if child_age >= 18
      return Membership.new.tap { |m| m.errors.add(:base, "L'enfant a 18 ans ou plus, il doit adhérer seul") }
    end

    # Vérifier si c'est un essai gratuit (statut trial)
    create_trial = params[:create_trial] == "1" || child_params[:create_trial] == "1"

    # Toujours calculer les dates de saison (même pour les essais gratuits, car la DB exige end_date NOT NULL)
    start_date, end_date = Membership.current_season_dates

    # S'assurer que les dates sont valides (protection contre les valeurs nil)
    unless start_date.present? && end_date.present?
      Rails.logger.error("[MembershipsController] Erreur dans create_child_membership_from_params: start_date ou end_date est nil. start_date=#{start_date.inspect}, end_date=#{end_date.inspect}")
      return Membership.new.tap { |m| m.errors.add(:base, "Erreur lors du calcul des dates de saison. Veuillez réessayer ou contacter le support.") }
    end

    # Pour les essais gratuits, on stocke le montant correspondant à la catégorie choisie
    # (même si le paiement n'est pas encore effectué, l'essai gratuit permet juste de s'inscrire aux initiations)
    amount_cents = Membership.price_for_category(category)
    current_season = Membership.current_season_name

    if create_trial
      membership_status = :trial
    else
      membership_status = :pending
    end

    # Mettre à jour les préférences email de l'utilisateur si fournies
    if params[:user]
      current_user.update!(
        wants_initiation_mail: params[:user][:wants_initiation_mail] == "1",
        wants_events_mail: params[:user][:wants_events_mail] == "1"
      )
    end

    # Adhésion simple uniquement (plus d'option T-shirt)
    with_tshirt = false
    tshirt_size = nil
    tshirt_qty = 0

    # Vérifier les réponses au questionnaire de santé (9 questions) AVANT création
    has_health_issue = false
    all_answered_no = true
    all_answered = true
    (1..9).each do |i|
      answer = child_params["health_question_#{i}"]
      if answer.blank?
        all_answered = false
        all_answered_no = false
      elsif answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer == "no"
        # Réponse NON, continue
      else
        all_answered_no = false # Pas encore répondu
      end
    end

    # Vérifier que toutes les questions sont répondues
    unless all_answered
      return Membership.new.tap { |m| m.errors.add(:base, "Le questionnaire de santé est obligatoire. Veuillez répondre à toutes les questions avant de continuer.") }
    end

    # Traiter Standard et FFRS de la même manière : questionnaire obligatoire, certificat médical jamais obligatoire
    # Même logique pour Standard et FFRS : juste mettre le statut selon les réponses
    # Préparer les attributs du questionnaire de santé
    health_attrs = {
      health_questionnaire_status: has_health_issue ? "medical_required" : "ok"
    }
    (1..9).each do |i|
      answer = child_params["health_question_#{i}"]
      health_attrs["health_q#{i}"] = answer if answer.present?
    end

    # Double vérification : s'assurer que end_date est toujours défini (protection finale)
    unless end_date.present?
      Rails.logger.error("[MembershipsController] Erreur dans create_child_membership_from_params: end_date est nil juste avant la création. create_trial=#{create_trial.inspect}, membership_status=#{membership_status.inspect}")
      return Membership.new.tap { |m| m.errors.add(:base, "Erreur lors du calcul de la date de fin de saison. Veuillez réessayer ou contacter le support.") }
    end

    # Créer l'adhésion enfant
    membership = Membership.create!(
      user: current_user, # Le parent
      category: category,
      status: membership_status,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: true,
      child_first_name: child_first_name,
      child_last_name: child_last_name,
      child_date_of_birth: child_date_of_birth,
      is_minor: child_age < 18,
      parent_authorization: child_age < 16 ? (child_params[:parent_authorization] == "1") : false,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      parent_name: "#{current_user.first_name} #{current_user.last_name}",
      parent_email: current_user.email,
      parent_phone: current_user.phone,
      tshirt_variant_id: nil,
      tshirt_price_cents: nil,
      # Adhésion simple uniquement (plus d'option T-shirt)
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0,
      rgpd_consent: child_params[:rgpd_consent] == "1",
      legal_notices_accepted: child_params[:legal_notices_accepted] == "1",
      ffrs_data_sharing_consent: child_params[:ffrs_data_sharing_consent] == "1",
      # Questionnaire de santé
      **health_attrs
    )

    # Attacher le certificat médical si fourni
    if child_params[:medical_certificate].present?
      membership.medical_certificate.attach(child_params[:medical_certificate])
    end

    # Validation déjà effectuée avant création, pas besoin de re-vérifier ici

    # Le Payment sera créé lors du clic sur "Payer" dans /memberships
    # Pas de création automatique ici

    membership
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[MembershipsController] Erreur de validation lors de la création de l'adhésion enfant : #{e.record.errors.full_messages.join(', ')}")
    e.record
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    membership&.destroy
    raise e
  end

  # Créer une adhésion adulte sans paiement HelloAsso (espèces/chèques)
  def create_adult_membership_without_payment
    membership_params = params[:membership] || params
    category = membership_params[:category]

    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    current_season = Membership.current_season_name

    # Vérifier les adhésions existantes pour cette saison
    existing_memberships = current_user.memberships.personal.where(season: current_season)

    # Vérifier si une adhésion active existe (protection contre end_date nil)
    active_membership = existing_memberships.find { |m| m.active? && m.end_date.present? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    # Vérifier si une adhésion pending existe
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User
    user_update_params = {}
    user_update_params[:first_name] = membership_params[:first_name] if membership_params[:first_name].present?
    user_update_params[:last_name] = membership_params[:last_name] if membership_params[:last_name].present?
    user_update_params[:phone] = membership_params[:phone] if membership_params[:phone].present?
    user_update_params[:email] = membership_params[:email] if membership_params[:email].present?
    user_update_params[:address] = membership_params[:address] if membership_params[:address].present?
    user_update_params[:city] = membership_params[:city] if membership_params[:city].present?
    user_update_params[:postal_code] = membership_params[:postal_code] if membership_params[:postal_code].present?

    if membership_params[:date_of_birth].present?
      user_update_params[:date_of_birth] = membership_params[:date_of_birth]
    end

    if params[:user]
      user_update_params[:wants_initiation_mail] = params[:user][:wants_initiation_mail] == "1" if params[:user][:wants_initiation_mail].present?
      user_update_params[:wants_events_mail] = params[:user][:wants_events_mail] == "1" if params[:user][:wants_events_mail].present?
    end

    if user_update_params.any?
      current_user.update!(user_update_params)
    end

    if current_user.date_of_birth.blank?
      redirect_to new_membership_path(type: "adult"), alert: "La date de naissance est obligatoire pour adhérer."
      return
    end

    user_age = current_user.age
    if user_age < 16
      redirect_to new_membership_path(type: "adult"), alert: "L'adhésion adulte n'est pas possible pour les personnes de moins de 16 ans. Veuillez contacter un membre du bureau de l'association pour procéder à l'adhésion. #{helpers.link_to('Contactez-nous', contact_path, class: 'alert-link')} pour plus d'informations.".html_safe
      return
    end

    # Vérifier les réponses au questionnaire de santé
    has_health_issue = false
    all_answered_no = true
    all_answered = true
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      if answer.blank?
        all_answered = false
        all_answered_no = false
      elsif answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer != "no"
        all_answered_no = false
      end
    end

    # Traiter Standard et FFRS de la même manière : questionnaire obligatoire, certificat médical jamais obligatoire
    # Vérifier que toutes les questions sont répondues
    unless all_answered
      redirect_to new_membership_path(type: "adult"), alert: "Le questionnaire de santé est obligatoire. Veuillez répondre à toutes les questions avant de continuer."
      return
    end

    # Même logique pour Standard et FFRS : juste mettre le statut selon les réponses
    membership_params[:health_questionnaire_status] = has_health_issue ? "medical_required" : "ok"

    # Préparer les attributs du questionnaire de santé
    health_attrs = {
      health_questionnaire_status: membership_params[:health_questionnaire_status] || "ok"
    }
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      health_attrs["health_q#{i}"] = answer if answer.present?
    end

    # S'assurer que end_date est défini avant la création (double vérification)
    unless end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: end_date est nil juste avant la création de l'adhésion")
      redirect_to new_membership_path, alert: "Erreur lors du calcul de la date de fin de saison. Veuillez réessayer ou contacter le support."
      return
    end

    # S'assurer que end_date est défini avant la création (double vérification)
    unless end_date.present?
      Rails.logger.error("[MembershipsController] Erreur: end_date est nil juste avant la création de l'adhésion")
      redirect_to new_membership_path, alert: "Erreur lors du calcul de la date de fin de saison. Veuillez réessayer ou contacter le support."
      return
    end

    # Créer l'adhésion en pending SANS paiement HelloAsso
    # Note: On utilise explicitement start_date et end_date calculés, pas ceux des paramètres
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: false,
      is_minor: current_user.is_minor?,
      tshirt_variant_id: nil,
      tshirt_price_cents: nil,
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0,
      **health_attrs
    )

    # Attacher le certificat médical si fourni
    if membership_params[:medical_certificate].present?
      membership.medical_certificate.attach(membership_params[:medical_certificate])
    end

    # PAS de création de paiement HelloAsso - l'adhésion reste en pending
    # Un bénévole/admin pourra la valider manuellement dans ActiveAdmin

    redirect_to membership_path(membership), notice: "Votre adhésion a été créée avec le statut 'En attente'. Un bénévole validera votre paiement en espèces/chèque prochainement."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion sans paiement : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end

  def create_teen_membership_without_payment
    # Similaire à create_adult_membership_without_payment mais pour les ados
    # Pour simplifier, on peut réutiliser la même logique
    create_adult_membership_without_payment
  end

  def create_child_membership_without_payment
    membership_params = params[:membership] || params
    membership = create_child_membership_from_params(membership_params, 0)

    if membership.persisted?
      redirect_to memberships_path, notice: "L'adhésion de #{membership.child_full_name} a été créée avec le statut 'En attente'. Un bénévole validera votre paiement en espèces/chèque prochainement."
    else
      redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{membership.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[MembershipsController] Erreur de validation : #{e.record.errors.full_messages.join(', ')}")
    redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant sans paiement : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    error_message = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.join(", ") : e.message
    redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{error_message}"
  end
end
