# frozen_string_literal: true

module AdminPanel
  class ContactMessagesController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_contact_message, only: %i[show destroy]
    before_action :authorize_contact_message, only: %i[show destroy]
    before_action :set_contact_discord_channel, only: %i[index update_discord_settings test_discord]

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
        notify_discord("contact_message.destroyed", @contact_message)
        flash[:notice] = "Le message ##{@contact_message.id} a été supprimé avec succès."
        redirect_to admin_panel_contact_messages_path
      else
        flash[:alert] = "Impossible de supprimer le message : #{@contact_message.errors.full_messages.join(', ')}"
        redirect_to admin_panel_contact_message_path(@contact_message)
      end
    end

    # PATCH /admin-panel/contact-messages/update_discord_settings
    def update_discord_settings
      authorize [ :admin_panel, ContactMessage ], :configure_discord?

      attributes = discord_channel_params
      attributes.delete(:webhook_url) if attributes[:webhook_url].blank?

      saved = false
      ActiveRecord::Base.transaction do
        @contact_discord_channel.assign_attributes(attributes)
        @contact_discord_channel.name = NotificationChannel::CONTACT_MESSAGES_NAME if @contact_discord_channel.name.blank?
        @contact_discord_channel.purpose = NotificationChannel::CONTACT_MESSAGES_PURPOSE

        saved = @contact_discord_channel.save
        raise ActiveRecord::Rollback unless saved

        @contact_discord_channel.ensure_contact_messages_subscription!
      end

      if saved
        status = @contact_discord_channel.enabled? ? "activées" : "désactivées"
        flash[:notice] = "Notifications Discord des messages de contact #{status}."
      else
        flash[:alert] = "Impossible d'enregistrer : #{@contact_discord_channel.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_contact_messages_path
    end

    # POST /admin-panel/contact-messages/test_discord
    def test_discord
      authorize [ :admin_panel, ContactMessage ], :test_discord?

      webhook_url = params.dig(:notification_channel, :webhook_url).presence
      webhook_url = @contact_discord_channel.webhook_url if webhook_url.blank? && @contact_discord_channel.webhook_configured?

      if webhook_url.blank?
        flash[:alert] = "Saisissez ou enregistrez d'abord une URL de webhook Discord."
        return redirect_to admin_panel_contact_messages_path
      end

      unless discord_webhook_host_allowed?(webhook_url)
        flash[:alert] = "L'URL doit être un webhook Discord (discord.com ou discordapp.com)."
        return redirect_to admin_panel_contact_messages_path
      end

      payload = NotificationEventRegistry.build_payload(
        "test.ping",
        source: @contact_discord_channel.persisted? ? @contact_discord_channel : NotificationChannel::CONTACT_MESSAGES_NAME
      )
      DiscordWebhookClient.post!(webhook_url, payload)

      if @contact_discord_channel.persisted?
        @contact_discord_channel.update!(
          last_tested_at: Time.current,
          last_test_status: "success"
        )
      end

      flash[:notice] = "Notification de test envoyée sur Discord."
      redirect_to admin_panel_contact_messages_path
    rescue DiscordWebhookClient::DeliveryError => e
      if @contact_discord_channel.persisted?
        @contact_discord_channel.update!(
          last_tested_at: Time.current,
          last_test_status: "error"
        )
      end

      detail = e.response_body.presence || e.message
      flash[:alert] = "Échec du test Discord#{e.http_code ? " (HTTP #{e.http_code})" : ""} : #{detail}"
      redirect_to admin_panel_contact_messages_path
    end

    private

    def set_contact_message
      @contact_message = ContactMessage.find(params[:id])
    end

    def authorize_contact_message
      authorize [ :admin_panel, @contact_message ]
    end

    def set_contact_discord_channel
      @contact_discord_channel = NotificationChannel.contact_messages_channel
    end

    def discord_channel_params
      params.require(:notification_channel).permit(:webhook_url, :enabled)
    end

    def discord_webhook_host_allowed?(url)
      uri = URI.parse(url)
      NotificationChannel::ALLOWED_WEBHOOK_HOSTS.include?(uri.host.to_s)
    rescue URI::InvalidURIError
      false
    end
  end
end
