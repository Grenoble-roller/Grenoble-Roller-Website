# 🎮 CONTROLLERS - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Controllers pour initiations et stock rollers.

---

## ✅ Controller 1 : InitiationsController

**Fichier** : `app/controllers/admin_panel/initiations_controller.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  class InitiationsController < BaseController
    before_action :set_initiation, only: %i[show
                                             presences update_presences
                                             convert_waitlist notify_waitlist
                                             toggle_volunteer
                                             return_material]
    before_action :authorize_initiation

    # GET /admin-panel/initiations
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

    # GET /admin-panel/initiations/:id
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
    end

    # GET /admin-panel/initiations/:id/presences
    def presences
      @volunteers = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: true)
        .where(status: %w[registered present no_show])
        .order(:created_at)

      @participants = @initiation.attendances
        .includes(:user, :child_membership)
        .where(is_volunteer: false)
        .where(status: %w[registered present no_show])
        .order(:created_at)
    end

    # PATCH /admin-panel/initiations/:id/update_presences
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

    # POST /admin-panel/initiations/:id/convert_waitlist
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

      if pending_attendance&.update(status: 'registered')
        waitlist_entry.update!(status: 'converted')
        WaitlistEntry.notify_next_in_queue(@initiation) if @initiation.has_available_spots?
        redirect_to admin_panel_initiation_path(@initiation),
                    notice: 'Entrée convertie en inscription'
      else
        redirect_to admin_panel_initiation_path(@initiation),
                    alert: 'Impossible de convertir l\'entrée'
      end
    end

    # POST /admin-panel/initiations/:id/notify_waitlist
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

    # PATCH /admin-panel/initiations/:id/toggle_volunteer
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

    # POST /admin-panel/initiations/:id/return_material
    # Marque le matériel comme rendu et remet les rollers en stock
    def return_material
      authorize [:admin_panel, @initiation], :return_material?

      # Vérifier que l'initiation est passée
      if @initiation.start_at.present? && @initiation.start_at > Time.current
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "L'initiation n'est pas encore terminée"
        return
      end

      # Vérifier que le matériel n'a pas déjà été rendu
      if @initiation.stock_returned_at.present?
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "Le matériel a déjà été marqué comme rendu le #{l(@initiation.stock_returned_at, format: :short)}"
        return
      end

      # Remettre le stock en place
      rollers_returned = @initiation.return_roller_stock

      if rollers_returned && rollers_returned > 0
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    notice: "Matériel rendu avec succès. #{rollers_returned} roller(s) remis en stock."
      elsif rollers_returned == 0
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    notice: "Aucun matériel à remettre en stock pour cette initiation."
      else
        redirect_to presences_admin_panel_initiation_path(@initiation),
                    alert: "Erreur lors de la remise en stock du matériel."
      end
    end

    private

    def set_initiation
      @initiation = ::Event::Initiation.find(params[:id])
    end

    def authorize_initiation
      authorize ::Event::Initiation, policy_class: AdminPanel::Event::InitiationPolicy
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

## ✅ Controller 2 : RollerStockController

**Fichier** : `app/controllers/admin_panel/roller_stocks_controller.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  class RollerStocksController < BaseController
    before_action :set_roller_stock, only: %i[show edit update destroy]
    before_action :authorize_roller_stock

    # GET /admin-panel/roller_stocks
    def index
      authorize [:admin_panel, RollerStock]

      @roller_stocks = RollerStock.all.ordered_by_size

      # Filtres
      @roller_stocks = @roller_stocks.where(is_active: params[:is_active]) if params[:is_active].present?
      @roller_stocks = @roller_stocks.available if params[:scope] == 'available'
      @roller_stocks = @roller_stocks.where('quantity <= ?', params[:low_stock]) if params[:low_stock].present?

      # Recherche
      if params[:q].present?
        @q = @roller_stocks.ransack(params[:q])
        @roller_stocks = @q.result
      end

      # Pagination
      @pagy, @roller_stocks = pagy(@roller_stocks, @pagy_options)

      # Demandes en attente (attendances avec besoin matériel)
      @pending_requests = Attendance
        .includes(:user, :child_membership, :event)
        .where(needs_equipment: true, roller_size: @roller_stocks.pluck(:size))
        .where(status: %w[registered present])
        .where(events: { type: 'Event::Initiation' })
        .order(:created_at)
    end

    # GET /admin-panel/roller_stocks/:id
    def show
      # Historique des demandes pour cette taille
      @requests = Attendance
        .includes(:user, :child_membership, :event)
        .where(roller_size: @roller_stock.size, needs_equipment: true)
        .where(events: { type: 'Event::Initiation' })
        .order(created_at: :desc)
        .limit(50)
    end

    # GET /admin-panel/roller_stocks/new
    def new
      authorize [:admin_panel, RollerStock]
      @roller_stock = RollerStock.new
    end

    # POST /admin-panel/roller_stocks
    def create
      authorize [:admin_panel, RollerStock]
      @roller_stock = RollerStock.new(roller_stock_params)

      if @roller_stock.save
        redirect_to admin_panel_roller_stock_path(@roller_stock),
                    notice: 'Stock créé avec succès'
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/roller_stocks/:id/edit
    def edit
    end

    # PATCH /admin-panel/roller_stocks/:id
    def update
      if @roller_stock.update(roller_stock_params)
        redirect_to admin_panel_roller_stock_path(@roller_stock),
                    notice: 'Stock mis à jour avec succès'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/roller_stocks/:id
    def destroy
      @roller_stock.destroy
      redirect_to admin_panel_roller_stocks_path,
                  notice: 'Stock supprimé avec succès'
    end

    private

    def set_roller_stock
      @roller_stock = RollerStock.find(params[:id])
    end

    def authorize_roller_stock
      authorize [:admin_panel, RollerStock]
    end

    def roller_stock_params
      params.require(:roller_stock).permit(:size, :quantity, :is_active)
    end
  end
end
```

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Créer InitiationsController (séparation à venir/passées)
- [x] Créer RollerStocksController
- [x] Tester toutes les actions (tests RSpec)
- [x] Tester autorisations Pundit (permissions par grade)

---

## 🔐 Permissions

**BaseController** : Permet l'accès aux initiations pour level >= 30, bloque le reste pour level < 60.

**InitiationPolicy** :
- Lecture (index?, show?) : `level >= 30`
- Écriture (create?, update?, destroy?) : `level >= 60`
- Actions spéciales : `level >= 60`

**Voir** : [`../PERMISSIONS.md`](../PERMISSIONS.md) pour la documentation complète.

---

## 🧪 Tests RSpec

**Status** : ✅ Tests complets (voir [`09-tests.md`](./09-tests.md))

**Exécution** :
```bash
bundle exec rspec spec/requests/admin_panel/initiations_spec.rb
```

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md) | [Permissions](../PERMISSIONS.md)
