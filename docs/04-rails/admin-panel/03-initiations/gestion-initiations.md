# 🎓 INITIATIONS - Gestion Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Gestion complète des initiations : création, participants, bénévoles, liste d'attente, présences.

**Status** : ✅ **IMPLÉMENTÉ** - Module complet fonctionnel dans AdminPanel

**Fichier original** : `app/admin/event/initiations.rb` (ActiveAdmin) - ⚠️ Conservé pour référence

### Visibilité par statut (liste et fiche publiques)

- **Publiées** et **annulées** : visibles par tous (utilisateurs connectés ou non, comme pour les événements). Les initiations annulées restent affichées pour communiquer (pluie, gymnase indisponible, etc.).
- **Rejetées** : exclues de toutes les listes publiques (même pour modérateurs/admins) ; restent en BDD mais ne sont pas affichées.
- **Brouillon (draft)** : visibles uniquement par le créateur et les modérateurs/admins.

---

## 🎮 Controller

### **Controller InitiationsController**

**Fichier** : `app/controllers/admin_panel/initiations_controller.rb`

```ruby
module AdminPanel
  class InitiationsController < BaseController
    before_action :set_initiation, only: [:show, :edit, :update, :destroy, 
                                          :presences, :update_presences,
                                          :convert_waitlist, :notify_waitlist, 
                                          :toggle_volunteer]
    before_action :authorize_initiation
    
    def index
      authorize ::Event::Initiation, policy_class: AdminPanel::Event::InitiationPolicy

      base_scope = ::Event::Initiation
        .includes(:creator_user, :attendances, :waitlist_entries)

      # Filtres
      base_scope = base_scope.where(status: params[:status]) if params[:status].present?
      base_scope = base_scope.where(status: 'published') if params[:scope] == 'published'

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      base_scope = @q.result(distinct: true)

      # Séparer initiations à venir et passées
      now = Time.current
      
      # Si filtre "upcoming", ne garder que les à venir
      if params[:scope] == 'upcoming'
        @upcoming_initiations = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc) # Prochaines d'abord, triées par date croissante
        @past_initiations = [] # Ne pas afficher les passées
      else
        # Sinon, afficher les deux sections
        @upcoming_initiations = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc) # Prochaines d'abord, triées par date croissante

        @past_initiations = base_scope
          .where("start_at <= ?", now)
          .order(start_at: :desc) # Passées ensuite, triées par date décroissante (plus récentes d'abord)
      end

      # Pour la pagination, on combine les deux listes
      # Mais on affiche séparément dans la vue
      @initiations = @upcoming_initiations + @past_initiations
    end
    
    def show
      @volunteers = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: true)
        .order(:created_at)

      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false)
        .order(:created_at)

      @waitlist_entries = @initiation.waitlist_entries
        .includes(:user, :child_membership)
        .active
        .ordered_by_position

      # Récapitulatif matériel demandé
      @equipment_requests = @initiation.attendances
        .where(needs_equipment: true)
        .where.not(roller_size: nil)
        .includes(:user, :child_membership)
        .group_by(&:roller_size)
        .transform_values { |attendances| attendances.count }
      
      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false)
        .order(:created_at)
      
      @waitlist_entries = @initiation.waitlist_entries
        .includes(:user, :child_membership)
        .active
        .ordered_by_position
    end
    
    def presences
      @volunteers = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: true, status: ['registered', 'present', 'no_show'])
        .order(:created_at)
      
      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false, status: ['registered', 'present', 'no_show'])
        .order(:created_at)
    end
    
    def update_presences
      attendance_ids = params[:attendance_ids] || []
      presences = params[:presences] || {}
      is_volunteer_changes = params[:is_volunteer] || {}
      
      attendance_ids.each do |attendance_id|
        attendance = @initiation.attendances.find_by(id: attendance_id)
        next unless attendance
        
        if presences[attendance_id.to_s].present?
          attendance.update(status: presences[attendance_id.to_s])
        end
        
        if is_volunteer_changes[attendance_id.to_s].present?
          attendance.update(is_volunteer: is_volunteer_changes[attendance_id.to_s] == '1')
        end
      end
      
      redirect_to presences_admin_panel_initiation_path(@initiation), 
                  notice: 'Présences mises à jour avec succès'
    end
    
    def convert_waitlist
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])
      
      unless waitlist_entry&.notified?
        redirect_to admin_panel_initiation_path(@initiation), 
                    alert: 'Entrée de liste d\'attente non notifiée'
        return
      end
      
      pending_attendance = @initiation.attendances.find_by(
        user: waitlist_entry.user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: 'pending'
      )
      
      if pending_attendance&.update_column(:status, 'registered')
        waitlist_entry.update!(status: 'converted')
        WaitlistEntry.notify_next_in_queue(@initiation) if @initiation.has_available_spots?
        redirect_to admin_panel_initiation_path(@initiation), 
                    notice: 'Entrée convertie en inscription'
      else
        redirect_to admin_panel_initiation_path(@initiation), 
                    alert: 'Impossible de convertir l\'entrée'
      end
    end
    
    def notify_waitlist
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])
      
      unless waitlist_entry&.pending?
        redirect_to admin_panel_initiation_path(@initiation), 
                    alert: 'Entrée non en attente'
        return
      end
      
      if waitlist_entry.notify!
        redirect_to admin_panel_initiation_path(@initiation), 
                    notice: 'Personne notifiée avec succès'
      else
        redirect_to admin_panel_initiation_path(@initiation), 
                    alert: 'Impossible de notifier'
      end
    end
    
    def toggle_volunteer
      attendance = @initiation.attendances.find_by(id: params[:attendance_id])
      
      if attendance&.update(is_volunteer: !attendance.is_volunteer)
        status = attendance.is_volunteer? ? 'ajouté' : 'retiré'
        redirect_to admin_panel_initiation_path(@initiation), 
                    notice: "Statut bénévole #{status}"
      else
        redirect_to admin_panel_initiation_path(@initiation), 
                    alert: 'Inscription introuvable'
      end
    end
    
    private
    
    def set_initiation
      @initiation = Event::Initiation.find(params[:id])
    end
    
    def authorize_initiation
      authorize [:admin_panel, Event::Initiation]
    end
    
    def initiation_params
      params.require(:event_initiation).permit(
        :title, :description, :start_at, :duration_min, :max_participants,
        :status, :location_text, :meeting_lat, :meeting_lng,
        :creator_user_id, :level, :distance_km
      )
    end
  end
end
```

---

## 🔐 Policy

### **Policy InitiationPolicy**

**Fichier** : `app/policies/admin_panel/initiation_policy.rb`

```ruby
module AdminPanel
  class InitiationPolicy < BasePolicy
    def index?
      admin_user?
    end
    
    def show?
      admin_user?
    end
    
    def create?
      admin_user?
    end
    
    def update?
      admin_user?
    end
    
    def destroy?
      admin_user?
    end
    
    def presences?
      admin_user?
    end
    
    def update_presences?
      admin_user?
    end
    
    def convert_waitlist?
      admin_user?
    end
    
    def notify_waitlist?
      admin_user?
    end
    
    def toggle_volunteer?
      admin_user?
    end
  end
end
```

---

## 🛣️ Routes

**Fichier** : `config/routes.rb`

```ruby
resources :initiations do
  member do
    get :presences
    patch :update_presences
    post :convert_waitlist
    post :notify_waitlist
    patch :toggle_volunteer
  end
end
```

---

## 🎨 Vues

### **Vue Index**

**Fichier** : `app/views/admin_panel/initiations/index.html.erb`

**Fonctionnalités** :
- Liste des initiations avec filtres (à venir, publiées, annulées)
- Colonnes : Titre, Date, Statut, Places, Participants, Bénévoles, Liste d'attente
- Pagination

### **Vue Show**

**Fichier** : `app/views/admin_panel/initiations/show.html.erb`

**Fonctionnalités** :
- Détails initiation
- Panel Bénévoles (tableau avec actions)
- Panel Participants (tableau avec actions)
- Panel Liste d'attente (convertir, notifier)
- Actions (convertir waitlist, notifier, toggle bénévole)

### **Vue Presences**

**Fichier** : `app/views/admin_panel/initiations/presences.html.erb`

**Fonctionnalités** :
- Dashboard présences
- Tableau bénévoles (présent/absent/no_show)
- Tableau participants (présent/absent/no_show)
- Mise à jour bulk

---

## ✅ Checklist

- [ ] Controller InitiationsController
- [ ] Policy InitiationPolicy
- [ ] Routes initiations
- [ ] Vue index
- [ ] Vue show
- [ ] Vue presences
- [ ] Partials (bénévoles, participants, waitlist)
- [ ] Tester workflow complet

---

## 📊 Référence ActiveAdmin

**Fichier actuel** : `app/admin/event/initiations.rb`

**Fonctionnalités à reproduire** :
- ✅ CRUD initiations
- ✅ Gestion participants/bénévoles
- ✅ Liste d'attente (convertir, notifier)
- ✅ Dashboard présences
- ✅ Toggle bénévole/participant

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
