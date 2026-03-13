class PagesController < ApplicationController
  def index
    # Les 2 prochains événements publiés à venir pour la section "Prochain rendez-vous" (2 cartes côte à côte)
    # Exclure les initiations (qui ont leur propre section)
    @highlighted_events = Event.not_initiations.published.upcoming
                               .includes(:route, :creator_user)
                               .order(:start_at)
                               .limit(2)

    # Statistiques synthétiques pour la homepage (événements + initiations)
    @users_count = User.count
    @events_count = Event.published.count
    @upcoming_events_count = Event.published.upcoming.count
    @attendances_count = Attendance.count
  end

  def association; end

  def about
    # Statistiques pour la page "À propos" (événements + initiations)
    @users_count = User.count
    @events_count = Event.published.count
    @upcoming_events_count = Event.published.upcoming.count
    @attendances_count = Attendance.count

    # Partenaires commerciaux actifs
    @commercial_partners = Partner.active.order(:name)
  end

  def welcome
    # Page de bienvenue après inscription
    # Permettre l'accès même si l'utilisateur n'est pas connecté (après inscription, l'utilisateur n'est pas automatiquement connecté)
    # Si l'utilisateur est connecté, utiliser ses informations, sinon afficher un message générique
    if user_signed_in?
      @user = current_user
      @next_steps = [
        {
          icon: "bi-envelope-check",
          title: "Confirmer votre email",
          description: "Un email vous attend dans votre boîte mail. Cliquez sur le lien pour activer votre compte et accéder à toutes les fonctionnalités.",
          action: "Vérifier mes emails",
          action_path: new_user_confirmation_path(email: @user.email),
          completed: @user.confirmed?
        },
        {
          icon: "bi-calendar-event",
          title: "Découvrir les événements",
          description: "Parcourez notre calendrier de randonnées urbaines et d'événements à thème. Inscrivez-vous à vos premières sorties roller !",
          action: "Voir les événements",
          action_path: events_path,
          completed: false
        },
        {
          icon: "bi-person-badge",
          title: "Rejoindre l'association",
          description: "Adhérez à Grenoble Roller pour participer à tous nos événements et bénéficier de tarifs préférentiels. Une communauté passionnée depuis plus de 20 ans !",
          action: "Voir les tarifs",
          action_path: new_membership_path(type: "adult"),
          completed: @user.has_active_membership?
        }
      ]
    else
      # Utilisateur non connecté (après inscription) - afficher un message générique
      @user = nil
      @next_steps = []
    end
  end
end
