# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  # ============ AFFICHAGE FORMULAIRE RENVOI ============

  def new
    # Appeler la méthode parente pour initialiser la resource
    super

    # Pré-remplir l'email si fourni en paramètre (depuis redirection)
    # Cela permet de pré-remplir le formulaire quand on arrive depuis :
    # - SessionsController (tentative de connexion avec email non confirmé)
    # - ApplicationController (accès bloqué car email non confirmé)
    if params[:email].present? && self.resource.present?
      self.resource.email = params[:email]
    end
  end

  # ============ RENVOI EMAIL ============

  def create
    email = confirmation_params[:email]&.downcase&.strip

    return render :new, alert: "Email requis" if email.blank?

    @user = User.find_by(email: email)

    case handle_resend_confirmation(email, @user)
    when :rate_limited
      render :new, alert: "Trop de demandes. Réessayez dans 1 heure."
    when :already_confirmed
      redirect_to root_path, notice: "Cet email est déjà confirmé ✓"
    when :not_found
      # Anti-énumération : même réponse si user existe ou non
      render :confirmed, notice: i18n_success_message
    when :success
      render :confirmed, notice: i18n_success_message(@user)
    end
  end

  # ============ CONFIRMATION VIA LIEN ============

  def show
    token = params[:confirmation_token]

    # SÉCURITÉ : Ne JAMAIS logguer le token en clair
    # Logging sécurisé (sans token)
    Rails.logger.info(
      "Confirmation attempt from IP: #{request.remote_ip}, " \
      "User-Agent: #{request.user_agent&.truncate(100)}, " \
      "Token present: #{token.present?}"
    )

    self.resource = resource_class.confirm_by_token(token)

    if resource.errors.empty?
      # Confirmation réussie - enregistrer audit trail
      record_confirmation_audit(resource)

      # Détection auto-click email scanner (après confirmation réussie)
      detect_email_scanner(resource) if resource.confirmation_sent_at

      # Message de bienvenue personnalisé après confirmation
      first_name = resource.first_name.presence || "membre"
      flash[:notice] = "Email confirmé avec succès ! 🎉 Bienvenue #{first_name}, votre compte est maintenant actif. Profitez de toutes les fonctionnalités de Grenoble Roller !"
      sign_in(resource_name, resource)
      redirect_to after_confirmation_path_for(resource)
    else
      # Échec de confirmation - détecter force brute
      detect_brute_force_attempt(request.remote_ip)
      handle_confirmation_error(resource)
    end
  end

  private

  # Enregistrer audit trail après confirmation réussie
  def record_confirmation_audit(user)
    user.update_columns(
      confirmed_ip: request.remote_ip,
      confirmed_user_agent: request.user_agent&.truncate(500),
      confirmation_token_last_used_at: Time.current
    )

    # Logging sécurisé (sans token)
    Rails.logger.info(
      "✅ Email confirmed successfully - User ID: #{user.id}, " \
      "Email: #{user.email}, IP: #{request.remote_ip}, " \
      "Time since sent: #{time_since_confirmation_sent(user)}"
    )
  end

  # Calculer temps écoulé depuis envoi email
  def time_since_confirmation_sent(user)
    return "N/A" unless user.confirmation_sent_at

    seconds = (Time.current - user.confirmation_sent_at).to_i
    if seconds < 60
      "#{seconds} secondes"
    elsif seconds < 3600
      "#{seconds / 60} minutes"
    else
      "#{seconds / 3600} heures"
    end
  end

  # Détecter auto-click email scanner (token cliqué < 10sec après envoi)
  def detect_email_scanner(user)
    return unless user.confirmation_sent_at

    time_since_sent = Time.current - user.confirmation_sent_at

    if time_since_sent < 10.seconds
      # Potentiel email scanner (auto-click trop rapide)
      Rails.logger.warn(
        "⚠️ Suspicious confirmation attempt - Possible email scanner detected. " \
        "User ID: #{user.id}, Time since sent: #{time_since_sent.to_i}s, IP: #{request.remote_ip}"
      )

      # Notifier service de sécurité
      EmailSecurityService.detect_email_scanner(user, request.remote_ip, time_since_sent)
    end
  end

  # Détecter attaque force brute (plusieurs échecs depuis même IP)
  def detect_brute_force_attempt(ip)
    cache_key = "confirmation_brute_force:#{ip}:#{Time.current.hour}"
    failure_count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour) || 1

    if failure_count > 50 # Seuil : 50 échecs/heure depuis même IP
      Rails.logger.error(
        "🚨 BRUTE FORCE ATTACK DETECTED - Confirmation failures: #{failure_count}, " \
        "IP: #{ip}, Hour: #{Time.current.hour}"
      )

      # Notifier service de sécurité (si configuré)
      EmailSecurityService.detect_brute_force(ip, failure_count) if defined?(EmailSecurityService)
    end
  end

  def handle_resend_confirmation(email, user)
    # Rate limiting (vérifie côté contrôleur aussi, en plus de Rack::Attack)
    return :rate_limited if rate_limit_exceeded?(email)

    # Email déjà confirmé
    return :already_confirmed if user&.confirmed?

    # Email non trouvé (anti-énumération : on ne révèle pas l'existence)
    return :not_found unless user

    # Envoyer email
    user.send_confirmation_instructions
    :success
  end

  def rate_limit_exceeded?(email)
    cache_key = "resend_confirmation:#{email}:#{Time.current.hour}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour) || 1
    count > 5 # Max 5 renvois par heure par email
  end

  def handle_confirmation_error(resource)
    if resource.respond_to?(:confirmation_token_expired?) && resource.confirmation_token_expired?
      redirect_to new_user_confirmation_path,
                  alert: "Lien expiré (> 3 jours). Veuillez demander un nouveau lien."
    elsif resource.errors.any?
      redirect_to new_user_confirmation_path,
                  alert: "Lien invalide ou déjà utilisé."
    end
  end

  def confirmation_params
    params.require(:user).permit(:email)
  end

  def i18n_success_message(user = nil)
    "Si l'email existe dans notre système, " \
    "vous recevrez les instructions de confirmation sous peu."
  end

  def after_confirmation_path_for(resource)
    if user_signed_in? && current_user == resource
      root_path
    else
      new_user_session_path
    end
  end
end
