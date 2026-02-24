# frozen_string_literal: true

module AdminPanel
  class BaseController < ApplicationController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    # Pundit est déjà inclus dans ApplicationController
    # before_action :authenticate_user! est géré par Devise
    before_action :authenticate_admin_user!
    before_action :set_pagy_options

    layout "admin"

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def authenticate_admin_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "Vous devez être connecté pour accéder à cette page."
        return
      end

      # Permissions par level uniquement (10, 20, 30, 40, 50, 60, 70)
      user_level = current_user&.role&.level.to_i

      # Initiations et homepage : level >= 30. Autres ressources : level >= 60
      if controller_name == "initiations" || controller_name == "homepage_carousels" || controller_name == "homepage_announcements"
        unless user_level >= 30
          redirect_to root_path, alert: "Accès non autorisé"
        end
      else
        unless user_level >= 60
          redirect_to root_path, alert: "Accès admin requis"
        end
      end
    end

    def set_pagy_options
      @pagy_options = { items: 25 }
    end

    def user_not_authorized(exception)
      flash[:alert] = "Vous n'êtes pas autorisé"
      redirect_to admin_panel_initiations_path
    end
  end
end
