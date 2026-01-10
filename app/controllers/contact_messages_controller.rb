# frozen_string_literal: true

class ContactMessagesController < ApplicationController
  # Pas besoin d'authentification pour le formulaire de contact

  # GET /contact
  def new
    @contact_message = ContactMessage.new
  end

  # POST /contact
  def create
    @contact_message = ContactMessage.new(contact_message_params)

    if @contact_message.save
      flash[:notice] = "Votre message a été envoyé avec succès. Nous vous répondrons dans les plus brefs délais."
      redirect_to contact_path, status: :see_other
    else
      flash.now[:alert] = "Erreur lors de l'envoi du message. Veuillez vérifier les informations saisies."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :subject, :message)
  end
end
