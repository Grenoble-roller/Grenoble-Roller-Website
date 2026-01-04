# frozen_string_literal: true

module AdminPanel
  class ContactMessagesController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_contact_message, only: %i[show destroy]
    before_action :authorize_contact_message, only: %i[show destroy]

    # GET /admin-panel/contact-messages
    def index
      authorize [ :admin_panel, ContactMessage ]

      # Recherche et filtres Ransack
      @q = ContactMessage.ransack(params[:q])
      @contact_messages = @q.result

      # Pagination
      @pagy, @contact_messages = pagy(@contact_messages.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/contact-messages/:id
    def show
      # Le contact_message est déjà chargé via set_contact_message
    end

    # DELETE /admin-panel/contact-messages/:id
    def destroy
      if @contact_message.destroy
        flash[:notice] = "Le message ##{@contact_message.id} a été supprimé avec succès."
        redirect_to admin_panel_contact_messages_path
      else
        flash[:alert] = "Impossible de supprimer le message : #{@contact_message.errors.full_messages.join(', ')}"
        redirect_to admin_panel_contact_message_path(@contact_message)
      end
    end

    private

    def set_contact_message
      @contact_message = ContactMessage.find(params[:id])
    end

    def authorize_contact_message
      authorize [ :admin_panel, @contact_message ]
    end
  end
end
