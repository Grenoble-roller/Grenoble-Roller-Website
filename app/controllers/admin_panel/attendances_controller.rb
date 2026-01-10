# frozen_string_literal: true

module AdminPanel
  class AttendancesController < BaseController
    before_action :set_attendance, only: %i[show edit update destroy]
    before_action :authorize_attendance

    # GET /admin-panel/attendances
    def index
      authorize ::Attendance, policy_class: AdminPanel::AttendancePolicy

      base_scope = ::Attendance.includes(:user, :event, :payment, :child_membership)

      # Filtres
      base_scope = base_scope.where(status: params[:status]) if params[:status].present?
      base_scope = base_scope.where(event_id: params[:event_id]) if params[:event_id].present?
      base_scope = base_scope.where(user_id: params[:user_id]) if params[:user_id].present?
      base_scope = base_scope.where(needs_equipment: params[:needs_equipment]) if params[:needs_equipment].present?
      base_scope = base_scope.where(roller_size: params[:roller_size]) if params[:roller_size].present?

      # Scopes
      base_scope = base_scope.active if params[:scope] == "active"
      base_scope = base_scope.canceled if params[:scope] == "canceled"

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      @attendances = @q.result(distinct: true).order(created_at: :desc)

      # Pagination
      @pagy, @attendances = pagy(@attendances, @pagy_options)
    end

    # GET /admin-panel/attendances/:id
    def show
      # L'attendance est déjà chargée via set_attendance
    end

    # GET /admin-panel/attendances/new
    def new
      @attendance = ::Attendance.new
      authorize @attendance, policy_class: AdminPanel::AttendancePolicy
    end

    # POST /admin-panel/attendances
    def create
      @attendance = ::Attendance.new(attendance_params)
      authorize @attendance, policy_class: AdminPanel::AttendancePolicy

      if @attendance.save
        flash[:notice] = "Participation créée avec succès"
        redirect_to admin_panel_attendance_path(@attendance)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/attendances/:id/edit
    def edit
      # L'attendance est déjà chargée via set_attendance
    end

    # PATCH/PUT /admin-panel/attendances/:id
    def update
      if @attendance.update(attendance_params)
        flash[:notice] = "Participation mise à jour avec succès"
        redirect_to admin_panel_attendance_path(@attendance)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/attendances/:id
    def destroy
      if @attendance.destroy
        flash[:notice] = "Participation supprimée avec succès"
        redirect_to admin_panel_attendances_path
      else
        flash[:alert] = "Impossible de supprimer la participation : #{@attendance.errors.full_messages.join(', ')}"
        redirect_to admin_panel_attendance_path(@attendance)
      end
    end

    private

    def set_attendance
      @attendance = ::Attendance.find(params[:id])
    end

    def authorize_attendance
      authorize ::Attendance, policy_class: AdminPanel::AttendancePolicy
    end

    def attendance_params
      params.require(:attendance).permit(
        :user_id, :event_id, :status, :payment_id, :stripe_customer_id,
        :is_volunteer, :free_trial_used, :wants_reminder, :equipment_note,
        :needs_equipment, :roller_size, :child_membership_id
      )
    end
  end
end
