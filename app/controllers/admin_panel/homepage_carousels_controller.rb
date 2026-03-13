# frozen_string_literal: true

module AdminPanel
  class HomepageCarouselsController < BaseController
    before_action :set_carousel, only: %i[show edit update destroy publish unpublish move_up move_down]
    before_action :authorize_carousel, only: %i[show edit update destroy publish unpublish move_up move_down]

    # GET /admin-panel/homepage-carousels
    def index
      authorize [ :admin_panel, HomepageCarousel ]

      # Recherche et filtres
      @q = HomepageCarousel.ransack(params[:q])
      @carousels = @q.result

      # Filtres supplémentaires
      @carousels = @carousels.where(published: params[:published]) if params[:published].present?

      # Pagination
      @pagy, @carousels = pagy(@carousels.ordered, items: params[:per_page] || 25)
    end

    # GET /admin-panel/homepage-carousels/:id
    def show
    end

    # GET /admin-panel/homepage-carousels/new
    def new
      @carousel = HomepageCarousel.new
      @carousel.published = false
      authorize [ :admin_panel, @carousel ]
    end

    # POST /admin-panel/homepage-carousels
    def create
      @carousel = HomepageCarousel.new(carousel_params)
      authorize [ :admin_panel, @carousel ]

      # Position auto (dernier + 1)
      @carousel.position ||= (HomepageCarousel.maximum(:position) || 0) + 1

      if @carousel.save
        flash[:notice] = "Slide créé avec succès"
        redirect_to admin_panel_homepage_carousel_path(@carousel)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/homepage-carousels/:id/edit
    def edit
    end

    # PATCH /admin-panel/homepage-carousels/:id
    def update
      if @carousel.update(carousel_params)
        flash[:notice] = "Slide mis à jour avec succès"
        redirect_to admin_panel_homepage_carousel_path(@carousel)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/homepage-carousels/:id
    def destroy
      @carousel.destroy
      flash[:notice] = "Slide supprimé avec succès"
      redirect_to admin_panel_homepage_carousels_path
    end

    # POST /admin-panel/homepage-carousels/:id/publish
    def publish
      if @carousel.update(published: true, published_at: Time.current)
        flash[:notice] = "Slide publié avec succès"
      else
        flash[:alert] = "Erreur : #{@carousel.errors.full_messages.join(', ')}"
      end
      redirect_to admin_panel_homepage_carousel_path(@carousel)
    end

    # POST /admin-panel/homepage-carousels/:id/unpublish
    def unpublish
      if @carousel.update(published: false)
        flash[:notice] = "Slide dépublié avec succès"
      else
        flash[:alert] = "Erreur : #{@carousel.errors.full_messages.join(', ')}"
      end
      redirect_to admin_panel_homepage_carousel_path(@carousel)
    end

    # PATCH /admin-panel/homepage-carousels/:id/move_up
    def move_up
      previous = HomepageCarousel.where("position < ?", @carousel.position).ordered.last
      if previous
        old_pos = @carousel.position
        new_pos = previous.position
        @carousel.update_column(:position, new_pos)
        previous.update_column(:position, old_pos)
        flash[:notice] = "Position mise à jour"
      else
        flash[:alert] = "Déjà en première position"
      end
      redirect_to admin_panel_homepage_carousels_path
    end

    # PATCH /admin-panel/homepage-carousels/:id/move_down
    def move_down
      next_item = HomepageCarousel.where("position > ?", @carousel.position).ordered.first
      if next_item
        old_pos = @carousel.position
        new_pos = next_item.position
        @carousel.update_column(:position, new_pos)
        next_item.update_column(:position, old_pos)
        flash[:notice] = "Position mise à jour"
      else
        flash[:alert] = "Déjà en dernière position"
      end
      redirect_to admin_panel_homepage_carousels_path
    end

    # PATCH /admin-panel/homepage-carousels/reorder
    def reorder
      authorize [ :admin_panel, HomepageCarousel ]

      positions = params[:positions] || []
      positions.each_with_index do |id, index|
        HomepageCarousel.where(id: id).update_all(position: index + 1)
      end

      head :ok
    end

    private

    def set_carousel
      @carousel = HomepageCarousel.find(params[:id])
    end

    def authorize_carousel
      authorize [ :admin_panel, @carousel ]
    end

    def carousel_params
      params.require(:homepage_carousel).permit(:title, :subtitle, :link_url, :position, :published, :published_at, :expires_at, :image)
    end
  end
end
