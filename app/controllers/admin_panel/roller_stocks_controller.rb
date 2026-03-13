# frozen_string_literal: true

module AdminPanel
  class RollerStocksController < BaseController
    before_action :set_roller_stock, only: %i[show edit update destroy]
    before_action :authorize_roller_stock

    # POST /admin-panel/roller_stocks/return_all
    # Remet en stock tous les rollers des initiations déjà terminées et non encore marquées "Matériel rendu".
    # Équivalent à cliquer "Matériel rendu" sur chaque initiation concernée.
    def return_all
      authorize [ :admin_panel, RollerStock ]

      now = Time.current
      finished_initiations = ::Event::Initiation
        .published
        .where("start_at + INTERVAL '1 minute' * duration_min <= ?", now)
        .where(stock_returned_at: nil)
        .includes(:attendances)

      count_initiations = 0
      total_rollers = 0

      finished_initiations.find_each do |initiation|
        has_equipment = initiation.attendances
          .where(needs_equipment: true)
          .where.not(roller_size: nil)
          .where.not(status: "canceled")
          .exists?
        next unless has_equipment

        returned = initiation.return_roller_stock
        next if returned.nil? # déjà traité (stock_returned_at présent)

        count_initiations += 1
        total_rollers += returned.to_i
      end

      if count_initiations > 0
        redirect_to admin_panel_roller_stocks_path,
                    notice: "#{count_initiations} initiation(s) traitée(s), #{total_rollers} roller(s) remis en stock."
      else
        redirect_to admin_panel_roller_stocks_path,
                    notice: "Aucune initiation terminée à traiter (tout le matériel est déjà remis en stock)."
      end
    end

    # GET /admin-panel/roller_stocks
    def index
      authorize [ :admin_panel, RollerStock ]

      @roller_stocks = RollerStock.all.ordered_by_size

      # Filtres
      @roller_stocks = @roller_stocks.where(is_active: params[:is_active]) if params[:is_active].present?
      @roller_stocks = @roller_stocks.available if params[:scope] == "available"
      @roller_stocks = @roller_stocks.where("quantity <= ?", params[:low_stock]) if params[:low_stock].present?

      # Recherche
      @q = @roller_stocks.ransack(params[:q])
      @roller_stocks = @q.result if params[:q].present?

      # Pagination
      @pagy, @roller_stocks = pagy(@roller_stocks, @pagy_options)

      # Demandes en attente (attendances avec besoin matériel)
      @pending_requests = Attendance
        .includes(:user, :child_membership, :event)
        .where(needs_equipment: true, roller_size: @roller_stocks.pluck(:size))
        .where(status: %w[registered present])
        .where(events: { type: "Event::Initiation" })
        .order(:created_at)
    end

    # GET /admin-panel/roller_stocks/:id
    def show
      # Historique des demandes pour cette taille
      @requests = Attendance
        .includes(:user, :child_membership, :event)
        .where(roller_size: @roller_stock.size, needs_equipment: true)
        .where(events: { type: "Event::Initiation" })
        .order(created_at: :desc)
        .limit(50)
    end

    # GET /admin-panel/roller_stocks/new
    def new
      authorize [ :admin_panel, RollerStock ]
      @roller_stock = RollerStock.new
    end

    # POST /admin-panel/roller_stocks
    def create
      authorize [ :admin_panel, RollerStock ]
      @roller_stock = RollerStock.new(roller_stock_params)

      if @roller_stock.save
        redirect_to admin_panel_roller_stock_path(@roller_stock),
                    notice: "Stock créé avec succès"
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
                    notice: "Stock mis à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/roller_stocks/:id
    def destroy
      @roller_stock.destroy
      redirect_to admin_panel_roller_stocks_path,
                  notice: "Stock supprimé avec succès"
    end

    private

    def set_roller_stock
      @roller_stock = RollerStock.find(params[:id])
    end

    def authorize_roller_stock
      authorize [ :admin_panel, RollerStock ]
    end

    def roller_stock_params
      params.require(:roller_stock).permit(:size, :quantity, :is_active)
    end
  end
end
