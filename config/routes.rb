Rails.application.routes.draw do
  # ActiveAdmin désactivé - Tout migré vers AdminPanel (2025-01-13)
  # ActiveAdmin.routes(self)

  # ===== NOUVEAU PANEL ADMIN =====
  namespace :admin_panel, path: "admin-panel" do
    root "dashboard#index"

    # Mission Control Jobs - Dashboard pour monitoring des jobs Solid Queue
    mount MissionControl::Jobs::Engine, at: "/jobs"

    # Logs des emails (SUPERADMIN uniquement)
    resources :mail_logs, path: "mail-logs", only: [ :index, :show ]

    resources :products do
      member do
        post :publish
        post :unpublish
      end
      resources :product_variants do
        collection do
          get :bulk_edit
          patch :bulk_update
        end
        member do
          patch :toggle_status
        end
      end
      collection do
        get :check_sku
        post :import
        get :export
        post :preview_variants
        patch :bulk_update_variants
      end
    end

    # Inventory
    get "inventory", to: "inventory#index"
    get "inventory/transfers", to: "inventory#transfers"
    patch "inventory/adjust_stock", to: "inventory#adjust_stock"

    resources :product_categories

    resources :orders do
      member { patch :change_status }
      collection { get :export }
    end

    # Paiements
    resources :payments, only: [ :index, :show, :destroy ]

    # Communication
    resources :contact_messages, path: "contact-messages", only: [ :index, :show, :destroy ]
    resources :partners

    # Initiations
    resources :initiations do
      member do
        get :presences
        patch :update_presences
        post :convert_waitlist
        post :notify_waitlist
        patch :toggle_volunteer
        post :return_material
      end
    end

    # Événements (Randonnées)
    # Note: new/create/edit/update sont gérés par le controller public EventsController
    resources :events, only: [ :index, :show, :destroy ] do
      member do
        post :convert_waitlist
        post :notify_waitlist
      end
    end

    # Routes (Parcours)
    resources :routes

    # Participations (Attendances)
    resources :attendances

    # Candidatures Organisateur
    # Note: new/create/edit/update ne sont pas nécessaires (candidatures créées par les utilisateurs)
    resources :organizer_applications, only: [ :index, :show, :destroy ] do
      member do
        patch :approve
        patch :reject
      end
    end

    # Roller Stock
    resources :roller_stocks, path: "roller-stocks" do
      collection do
        post :return_all
      end
    end

    # Utilisateurs
    resources :users
    resources :roles
    resources :memberships do
      member do
        patch :activate
        post :check_payment
      end
    end

    # Maintenance Mode (admin uniquement)
    resource :maintenance, only: [], controller: "maintenance" do
      member do
        patch :toggle
      end
    end

    # Homepage Content (level >= 40 : ORGANIZER+)
    resources :homepage_carousels, path: "homepage-carousels" do
      member do
        post :publish
        post :unpublish
        patch :move_up
        patch :move_down
      end
      collection do
        patch :reorder
      end
    end
  end

  # Ressource REST pour le mode maintenance
  namespace :activeadmin do
    resource :maintenance, only: [ :update ], controller: "/admin_legacy/maintenance_toggle" do
      member do
        patch :toggle
      end
    end
  end

  # Page maintenance simple (optionnel, pour tests)
  get "/maintenance", to: proc { |env|
    [
      200,
      { "Content-Type" => "text/html" },
      [ File.read(Rails.root.join("public", "maintenance.html")) ]
    ]
  }

  devise_for :users, controllers: {
    registrations: "registrations",
    sessions: "sessions",
    passwords: "passwords",
    confirmations: "confirmations"
  }

  # Route AJAX pour vérifier si un email existe déjà (validation en temps réel)
  get "/users/check_email", to: "registrations#check_email", as: "check_email_users"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Standard Rails endpoint - simple check (no DB queries)
  get "up" => "rails/health#show", as: :rails_health_check

  # Advanced health check with database connection and migrations status
  # Returns JSON with detailed status (DB + migrations) - useful for monitoring/alerting
  get "health" => "health#check", as: :health_check

  # PWA: manifest et service worker (liens dans application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "pages#index"

  # Static pages
  get "/welcome", to: "pages#welcome", as: "welcome"
  get "/a-propos", to: "pages#about", as: "about"
  get "/guide-images", to: "pages#guide_images", as: "guide_images"
  # Redirection 301 de /association vers /a-propos (fusion des pages)
  get "/association", to: redirect("/a-propos", status: 301), as: "association"

  # Shop
  resources :products, only: [ :index, :show ]
  get "/shop", to: "products#index", as: "shop"

  # Cart
  resource :cart, only: [ :show ] do
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end

  # Orders (Checkout)
  resources :orders, only: [ :index, :new, :create, :show ] do
    resources :payments, only: [ :create ], shallow: true, controller: "orders/payments" do
      collection do
        # Statut du paiement (peut être appelé même sans payment créé)
        get :status, action: :show
      end
    end
    member do
      patch :cancel
      post :check_payment
    end
  end

  # Memberships - Routes REST/CRUD
  resources :memberships, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    resources :payments, only: [ :create ], shallow: true, controller: "memberships/payments"
    # Route status nested (nécessite membership_id)
    get "payments/status", to: "memberships/payments#show", as: :status_payment
    member do
      # Convertir essai gratuit en adhésion payante
      patch :upgrade
      # Renouveler une adhésion expirée (enfant uniquement)
      post :renew
      # Vérifier le paiement HelloAsso
      post :check_payment
    end
    collection do
      # Paiement groupé pour plusieurs enfants en attente
      post "payments/create_multiple", to: "memberships/payments#create_multiple", as: :create_multiple_payments
      post :create_without_payment
      # Redirection de l'ancienne page choose vers new
      get :choose, to: redirect { |params, request|
        if params[:child] == "true"
          new_membership_path(type: "child", renew_from: params[:renew_from])
        else
          new_membership_path(type: "adult")
        end
      }
    end
  end

  # Events (Phase 2)
  resources :events do
    resources :attendances, only: [ :create ], shallow: true, controller: "events/attendances" do
      collection do
        delete :destroy
        patch :toggle_reminder
      end
    end
    resources :waitlist_entries, only: [ :create, :destroy ], shallow: true, controller: "events/waitlist_entries" do
      member do
        post :convert_to_attendance
        post :refuse
        get :confirm, path: "confirm"
        get :decline, path: "decline"
      end
    end
    member do
      get :loop_routes, defaults: { format: "json" }
      patch :reject
    end
  end

      # Initiations
      resources :initiations do
        resources :attendances, only: [ :create ], shallow: true, controller: "initiations/attendances" do
          collection do
            delete :destroy
            patch :toggle_reminder
          end
        end
        resources :waitlist_entries, only: [ :create, :destroy ], shallow: true, controller: "initiations/waitlist_entries" do
          member do
            post :convert_to_attendance
            post :refuse
            get :confirm, path: "confirm"
            get :decline, path: "decline"
          end
        end
      end

  # Routes REST pour les parcours
  resources :routes, only: [ :create ] do
    member do
      get :info, defaults: { format: "json" }
    end
  end

  resources :attendances, only: :index

  # Legal pages
  get "/mentions-legales", to: "legal_pages#mentions_legales", as: "mentions_legales"
  get "/politique-confidentialite", to: "legal_pages#politique_confidentialite", as: "politique_confidentialite"
  get "/rgpd", to: "legal_pages#politique_confidentialite" # Alias pour RGPD
  get "/cgv", to: "legal_pages#cgv", as: "cgv"
  get "/conditions-generales-vente", to: "legal_pages#cgv" # Alias pour CGV
  get "/cgu", to: "legal_pages#cgu", as: "cgu"
  get "/conditions-generales-utilisation", to: "legal_pages#cgu" # Alias pour CGU
  # Formulaire de contact public
  get "/contact", to: "contact_messages#new", as: "contact"
  post "/contact", to: "contact_messages#create"
  get "/faq", to: "legal_pages#faq", as: "faq"
  get "/questions-frequentes", to: "legal_pages#faq" # Alias pour FAQ

  # Cookie consent
  resource :cookie_consent, only: [] do
    collection do
      get :preferences
      post :accept
      post :reject
      patch :update
    end
  end
end
