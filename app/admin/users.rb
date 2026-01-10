ActiveAdmin.register User do
  menu priority: 1, label: "Utilisateurs", parent: "Utilisateurs"

  permit_params :email, :password, :password_confirmation,
                :first_name, :last_name, :bio, :phone, :avatar_url,
                :role_id, :date_of_birth,
                :address, :city, :postal_code, :skill_level,
                :wants_email_info, :wants_events_mail, :wants_initiation_mail, :wants_whatsapp,
                :can_be_volunteer

  includes :role

  index do
    selectable_column
    id_column
    column "Nom complet", :first_name do |user|
      user.to_s # Affiche "Prénom Nom"
    end
    column :email
    column :role
    column "Bénévole" do |user|
      status_tag(user.can_be_volunteer == true ? "Oui" : "Non", class: user.can_be_volunteer == true ? "ok" : "no")
    end
    column :confirmed? do |user|
      status_tag(user.confirmed? ? "Confirmé" : "Non confirmé", class: user.confirmed? ? "ok" : "error")
    end
    column :created_at
    actions
  end

  filter :email
  filter :unconfirmed_email
  filter :first_name
  filter :last_name
  filter :role
  filter :can_be_volunteer, as: :boolean
  filter :confirmed_at
  filter :date_of_birth
  filter :city
  filter :created_at

  show do
    attributes_table "Informations personnelles" do
      row :id
      row :email
      row :unconfirmed_email do |user|
        if user.unconfirmed_email.present?
          status_tag(user.unconfirmed_email, class: "warning") + " (En attente de confirmation)"
        else
          status_tag("Aucun", class: "ok")
        end
      end
      row :first_name
      row :last_name
      row :date_of_birth
      row :phone
      row :bio
      row :avatar do |user|
        if user.avatar.attached?
          image_tag(user.avatar, height: 150, style: "border-radius: 8px;")
        elsif user.avatar_url.present?
          image_tag(user.avatar_url, height: 150, style: "border-radius: 8px;")
        else
          status_tag("Aucun avatar", class: "warning")
        end
      end
      row :avatar_url
      row :skill_level
    end

    attributes_table "Adresse" do
      row :address
      row :city
      row :postal_code
    end

    attributes_table "Confirmation d'email (Devise)" do
      row :confirmed_at do |user|
        if user.confirmed_at.present?
          status_tag("Confirmé le #{user.confirmed_at.strftime('%d/%m/%Y à %H:%M')}", class: "ok")
        else
          status_tag("Non confirmé", class: "error")
        end
      end
      row :confirmed? do |user|
        status_tag(user.confirmed? ? "Oui" : "Non", class: user.confirmed? ? "ok" : "error")
      end
      row :confirmation_token do |user|
        if user.confirmation_token.present?
          "#{user.confirmation_token[0..10]}..." + " (masqué pour sécurité)"
        else
          status_tag("Aucun token", class: "ok")
        end
      end
      row :confirmation_sent_at do |user|
        user.confirmation_sent_at ? user.confirmation_sent_at.strftime("%d/%m/%Y à %H:%M") : "Jamais envoyé"
      end
      row :confirmation_token_last_used_at do |user|
        user.confirmation_token_last_used_at ? user.confirmation_token_last_used_at.strftime("%d/%m/%Y à %H:%M") : "Jamais utilisé"
      end
      row :confirmed_ip
      row :confirmed_user_agent do |user|
        user.confirmed_user_agent&.truncate(100)
      end
    end

    attributes_table "Autres informations" do
      row :role
      row :can_be_volunteer do |user|
        status_tag(user.can_be_volunteer == true ? "Oui" : "Non", class: user.can_be_volunteer == true ? "ok" : "no")
      end
      row :wants_email_info
      row :wants_events_mail
      row :wants_initiation_mail
      row :wants_whatsapp
      row :remember_created_at
      row :reset_password_sent_at
      row :created_at
      row :updated_at
    end

    panel "Inscriptions" do
      table_for user.attendances.includes(:event) do
        column :event
        column :status do |attendance|
          status_tag(attendance.status)
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Informations personnelles" do
      f.input :email
      f.input :first_name
      f.input :last_name
      f.input :date_of_birth, as: :date_picker
      f.input :phone
      f.input :bio
      f.input :skill_level
    end

    f.inputs "Adresse" do
      f.input :address
      f.input :city
      f.input :postal_code
    end

    f.inputs "Authentification" do
      f.input :password, hint: ("Laissez vide pour conserver le mot de passe actuel" if f.object.persisted?)
      f.input :password_confirmation
      f.input :role
    end

    f.inputs "Préférences" do
      f.input :wants_email_info
      f.input :wants_events_mail
      f.input :wants_initiation_mail
      f.input :wants_whatsapp
    end

    f.inputs "Bénévole" do
      f.input :can_be_volunteer,
              as: :boolean,
              label: "Peut être bénévole encadrant",
              hint: "Si coché, cet utilisateur pourra s'inscrire en tant que bénévole sur les initiations"
    end

    f.inputs "Avatar" do
      f.input :avatar, as: :file, hint: "Upload un avatar (recommandé)"
      f.input :avatar_url, hint: "Ou utilisez une URL (déprécié, pour transition)"
    end

    f.actions
  end

  controller do
    def create
      # Vérifier que le rôle assigné n'est pas supérieur au rôle de l'utilisateur actuel
      if params[:user] && params[:user][:role_id].present?
        new_role = Role.find_by(id: params[:user][:role_id])
        unless RoleAssignmentService.can_assign_role_to_user?(
          assigner: current_admin_user,
          target_user: resource,
          new_role: new_role
        )
          flash[:error] = "Vous ne pouvez pas assigner un rôle supérieur au vôtre"
          redirect_to collection_path
          return
        end
        # Passer l'utilisateur assigneur pour la validation du modèle
        resource.assigner_user = current_admin_user
      end
      super
    end

    def update
      if params[:user].present?
        # Gérer les champs password
        if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end

        # Gérer le boolean can_be_volunteer (si non présent dans les params, c'est false)
        # ActiveAdmin n'envoie pas les checkboxes non cochées
        unless params[:user].key?(:can_be_volunteer)
          params[:user][:can_be_volunteer] = false
        end

        # Vérifier que le rôle assigné n'est pas supérieur au rôle de l'utilisateur actuel
        if params[:user][:role_id].present?
          new_role = Role.find_by(id: params[:user][:role_id])
          unless RoleAssignmentService.can_assign_role_to_user?(
            assigner: current_admin_user,
            target_user: resource,
            new_role: new_role
          )
            flash[:error] = "Vous ne pouvez pas assigner un rôle supérieur au vôtre"
            redirect_to resource_path(resource)
            return
          end
          # Passer l'utilisateur assigneur pour la validation du modèle
          resource.assigner_user = current_admin_user
        end
      end
      super
    end

    def destroy
      @user = resource
      if @user.destroy
        redirect_to collection_path, notice: "L'utilisateur ##{@user.id} a été supprimé avec succès."
      else
        redirect_to resource_path(@user), alert: "Impossible de supprimer l'utilisateur : #{@user.errors.full_messages.join(', ')}"
      end
    end
  end
end
