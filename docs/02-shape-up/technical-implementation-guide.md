---
title: "Technical Implementation Guide"
status: "active"
version: "1.0"
created: "2025-01-20"
updated: "2025-11-14"
authors: ["FlowTech"]
tags: ["shape-up", "technical", "rails", "bootstrap", "implementation"]
---

# Technical Implementation Guide

**Project** : Grenoble Roller Community Platform  
**Stack** : Rails 8 + Bootstrap - Shape Up Technical Guide

---

## 📊 ÉTAT ACTUEL DU PROJET (Nov 2025)

### ✅ Phase 1 - E-commerce (TERMINÉE)
- ✅ Rails 8.0.4 configuré avec Docker (dev/staging/prod)
- ✅ Authentification Devise + 7 niveaux de rôles (USER à SUPERADMIN)
- ✅ E-commerce complet fonctionnel (catalogue, panier, checkout, commandes)
- ✅ Base de données PostgreSQL 16 avec 13 migrations appliquées
- ✅ Seeds complets (rôles, utilisateurs, produits, commandes, paiements)
- ✅ Documentation complète mise à jour

### 🔜 Phase 2 - Événements (À VENIR - 15 jours)
- 🔜 CRUD événements (Jour 6-8)
- 🔜 Inscriptions aux événements (Jour 9)
- 🔜 Calendrier interactif (Jour 9)
- ✅ Tests TDD >70% coverage (Jour 10)
- ✅ Permissions fines Pundit (Jour 11)
- ✅ Interface admin ActiveAdmin (Jour 12-13)
- 🔜 Upload photos (Active Storage) (Jour 14)
- 🔜 Notifications email (Jour 14)
- 🔜 Performance & Sécurité (Jour 15)

---

## 🎯 MÉTHODOLOGIE SHAPE UP

### Principe Fondamental
**Appetite fixe (3 semaines Building + 1 semaine Cooldown), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

### 4 Phases Shape Up
1. **SHAPING** (Semaine -2 à 0) : Définir les limites
2. **BETTING TABLE** (Semaine 0) : Priorisation brutale  
3. **BUILDING** (Semaine 1-3, 15 jours) : Livrer feature shippable
4. **COOLDOWN** (Semaine 4) : Repos obligatoire

### Rabbit Holes Évités
- ❌ Microservices → Monolithe Rails d'abord
- ❌ Kubernetes → Docker Compose simple
- ❌ Internationalisation → MVP français uniquement
- ❌ API publique → API interne uniquement

---


## 🏗️ ARCHITECTURE TECHNIQUE

### **Structure du projet Rails 8**

## 🚀 COMMANDES DE DÉMARRAGE

### **1. Initialisation du projet**
```bash
# Créer le projet Rails 8
rails new app --database=postgresql --css=bootstrap

# Aller dans le dossier
cd app

# Installer les gems
bundle install

# Configurer la base de données
rails db:create
rails db:migrate

# Démarrer le serveur
rails server
```

### **2. Configuration initiale**
```bash
# Ajouter les gems nécessaires
bundle add devise pundit sidekiq redis
bundle add rspec-rails capybara factory_bot_rails
bundle add rubocop rubocop-rails

# Configurer RSpec
rails generate rspec:install

# Configurer Devise
rails generate devise:install
rails generate devise User
rails generate devise:views

# Configurer Pundit
rails generate pundit:install
```

---

## 📦 GEMS RECOMMANDÉES

### **Authentification & Autorisation**
```ruby
# Gemfile
gem 'devise'                    # Authentification
gem 'pundit'                    # Autorisation
gem 'omniauth'                  # OAuth (optionnel)
gem 'omniauth-facebook'         # Facebook login
gem 'omniauth-twitter'          # Twitter login
```

### **UI & Frontend**
```ruby
gem 'bootstrap'                 # Framework CSS
gem 'stimulus-rails'            # JavaScript framework
gem 'turbo-rails'               # SPA navigation
gem 'fullcalendar-rails'        # Calendrier
gem 'chartkick'                 # Graphiques
gem 'kaminari'                  # Pagination
```

### **API & Intégrations**
```ruby
gem 'httparty'                  # HTTP requests
gem 'sidekiq'                   # Background jobs
gem 'redis'                     # Cache et sessions
gem 'whenever'                  # Cron jobs
```

### **Tests & Qualité**
```ruby
gem 'rspec-rails'               # Tests
gem 'capybara'                  # Tests d'intégration
gem 'factory_bot_rails'         # Factories
gem 'faker'                     # Données de test
gem 'rubocop'                   # Linting
gem 'brakeman'                  # Sécurité
```

### **Production**
```ruby
gem 'puma'                      # Serveur web
gem 'pg'                        # PostgreSQL
gem 'redis'                     # Cache
gem 'sidekiq'                   # Background jobs
gem 'rack-cors'                 # CORS
```

---

## 🗄️ MODÈLES DE DONNÉES

### **User (Utilisateur)**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { member: 0, staff: 1, admin: 2 }
  
  has_many :memberships
  has_many :event_registrations
  has_many :events, through: :event_registrations
  
  validates :first_name, :last_name, presence: true
  validates :phone, presence: true, format: { with: /\A\d{10}\z/ }
end
```

### **Event (Événement)**
```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :event_registrations
  has_many :participants, through: :event_registrations, source: :user
  
  enum event_type: { rando: 0, initiation: 1, other: 2 }
  enum status: { draft: 0, published: 1, cancelled: 2 }
  
  validates :title, :description, :start_date, presence: true
  validates :max_participants, numericality: { greater_than: 0 }
  
  scope :upcoming, -> { where('start_date > ?', Time.current) }
  scope :published, -> { where(status: :published) }
end
```

### **Membership (Adhésion)**
```ruby
# app/models/membership.rb
class Membership < ApplicationRecord
  belongs_to :user
  
  enum membership_type: { basic: 0, ffrs: 1, ffrs_insurance: 2 }
  enum status: { pending: 0, active: 1, expired: 2 }
  
  validates :membership_type, presence: true
  validates :start_date, presence: true
  
  def price
    case membership_type
    when 'basic' then 10.0
    when 'ffrs' then 56.55
    when 'ffrs_insurance' then 58.0
    end
  end
end
```

---

## 🎨 COMPOSANTS BOOTSTRAP

### **Navigation principale**
```erb
<!-- app/views/shared/_navbar.html.erb -->
<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
  <div class="container">
    <%= link_to "Grenoble Roller", root_path, class: "navbar-brand" %>
    
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
      <span class="navbar-toggler-icon"></span>
    </button>
    
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav me-auto">
        <li class="nav-item">
          <%= link_to "Événements", events_path, class: "nav-link" %>
        </li>
        <li class="nav-item">
          <%= link_to "Initiation", initiations_path, class: "nav-link" %>
        </li>
        <li class="nav-item">
          <%= link_to "Boutique", shop_path, class: "nav-link" %>
        </li>
      </ul>
      
      <ul class="navbar-nav">
        <% if user_signed_in? %>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
              <%= current_user.first_name %>
            </a>
            <ul class="dropdown-menu">
              <li><%= link_to "Mon profil", profile_path, class: "dropdown-item" %></li>
              <li><%= link_to "Mes événements", my_events_path, class: "dropdown-item" %></li>
              <% if current_user.admin? %>
                <li><hr class="dropdown-divider"></li>
                <li><%= link_to "Administration", admin_path, class: "dropdown-item" %></li>
              <% end %>
              <li><hr class="dropdown-divider"></li>
              <li><%= link_to "Déconnexion", destroy_user_session_path, method: :delete, class: "dropdown-item" %></li>
            </ul>
          </li>
        <% else %>
          <li class="nav-item">
            <%= link_to "Connexion", new_user_session_path, class: "nav-link" %>
          </li>
          <li class="nav-item">
            <%= link_to "Inscription", new_user_registration_path, class: "btn btn-outline-light" %>
          </li>
        <% end %>
      </ul>
    </div>
  </div>
</nav>
```

### **Carte d'événement**
```erb
<!-- app/views/events/_event_card.html.erb -->
<div class="col-md-6 col-lg-4 mb-4">
  <div class="card h-100">
    <div class="card-header bg-primary text-white">
      <h5 class="card-title mb-0"><%= event.title %></h5>
    </div>
    <div class="card-body">
      <p class="card-text"><%= truncate(event.description, length: 100) %></p>
      <div class="row text-muted small">
        <div class="col-6">
          <i class="bi bi-calendar"></i> <%= event.start_date.strftime("%d/%m/%Y") %>
        </div>
        <div class="col-6">
          <i class="bi bi-clock"></i> <%= event.start_date.strftime("%H:%M") %>
        </div>
      </div>
      <div class="mt-2">
        <span class="badge bg-<%= event.event_type == 'rando' ? 'success' : 'info' %>">
          <%= event.event_type.humanize %>
        </span>
        <span class="badge bg-secondary">
          <%= event.participants.count %>/<%= event.max_participants %> participants
        </span>
      </div>
    </div>
    <div class="card-footer">
      <%= link_to "Voir détails", event_path(event), class: "btn btn-primary btn-sm" %>
      <% if user_signed_in? && event.published? %>
        <% if event.participants.include?(current_user) %>
          <%= link_to "Se désinscrire", event_registration_path(event), method: :delete, 
                      class: "btn btn-outline-danger btn-sm" %>
        <% else %>
          <%= link_to "S'inscrire", event_registrations_path(event_id: event.id), method: :post, 
                      class: "btn btn-success btn-sm" %>
        <% end %>
      <% end %>
    </div>
  </div>
</div>
```

---

## 🧪 TESTS RSPEC

### **Configuration RSpec**
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
end
```

### **Test de modèle**
```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:phone) }
  end

  describe 'associations' do
    it { should have_many(:memberships) }
    it { should have_many(:event_registrations) }
    it { should have_many(:events).through(:event_registrations) }
  end

  describe 'roles' do
    it 'defaults to member role' do
      user = create(:user)
      expect(user.role).to eq('member')
    end
  end
end
```

### **Test de contrôleur**
```ruby
# spec/controllers/events_controller_spec.rb
require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new event' do
        expect {
          post :create, params: { event: attributes_for(:event) }
        }.to change(Event, :count).by(1)
      end
    end
  end
end
```

### **Test d'intégration**
```ruby
# spec/features/event_registration_spec.rb
require 'rails_helper'

RSpec.feature 'Event Registration', type: :feature do
  let(:user) { create(:user) }
  let(:event) { create(:event, :published) }

  scenario 'User registers for an event' do
    sign_in user
    visit event_path(event)
    
    click_button 'S\'inscrire'
    
    expect(page).to have_content('Inscription réussie')
    expect(event.participants).to include(user)
  end
end
```

---

## 🔧 CONFIGURATION CI/CD

### **GitHub Actions**
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.3.0
        bundler-cache: true
    
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
    
    - name: Install dependencies
      run: |
        bundle install
        npm install
    
    - name: Set up database
      run: |
        bundle exec rails db:create
        bundle exec rails db:migrate
    
    - name: Run tests
      run: |
        bundle exec rspec
        bundle exec rubocop
        bundle exec brakeman
```

---

## 🚀 DÉPLOIEMENT

### **Docker Compose**
```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/grenoble_roller
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: grenoble_roller
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    volumes:
      - redis_data:/data

  sidekiq:
    build: .
    command: bundle exec sidekiq
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/grenoble_roller
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
  redis_data:
```

### **Dockerfile**
```dockerfile
FROM ruby:3.3.0-alpine

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

---

## 📊 MONITORING

### **Métriques importantes**
```ruby
# config/initializers/monitoring.rb
if Rails.env.production?
  require 'prometheus/client'
  
  # Métriques personnalisées
  PROMETHEUS = Prometheus::Client.registry
  
  # Compteur d'événements créés
  events_created = PROMETHEUS.counter(
    :events_created_total,
    docstring: 'Total number of events created'
  )
  
  # Compteur d'inscriptions
  registrations_total = PROMETHEUS.counter(
    :event_registrations_total,
    docstring: 'Total number of event registrations'
  )
  
  # Gauge des utilisateurs actifs
  active_users = PROMETHEUS.gauge(
    :active_users_count,
    docstring: 'Number of active users'
  )
end
```

---

## 🔐 SÉCURITÉ

### **Configuration de sécurité**
```ruby
# config/application.rb
config.force_ssl = true
config.ssl_options = { redirect: { exclude: -> request { request.path =~ /health/ } } }

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.referrer_policy = "strict-origin-when-cross-origin"
end
```

---

## 📱 INTÉGRATIONS

### **HelloAsso API**
```ruby
# app/services/helloasso_service.rb
class HelloassoService
  include HTTParty
  base_uri 'https://api.helloasso.com/v5'
  
  def initialize
    @headers = {
      'Authorization' => "Bearer #{Rails.application.credentials.helloasso_token}",
      'Content-Type' => 'application/json'
    }
  end
  
  def create_order(order_data)
    self.class.post('/orders', {
      headers: @headers,
      body: order_data.to_json
    })
  end
end
```

### **Réseaux sociaux**
```ruby
# app/jobs/social_media_job.rb
class SocialMediaJob < ApplicationJob
  queue_as :default
  
  def perform(event_id)
    event = Event.find(event_id)
    
    # Post sur Twitter
    TwitterService.new.post_event(event)
    
    # Post sur Facebook
    FacebookService.new.post_event(event)
  end
end
```

---

## ✅ CHECKLIST PHASE 2

> **📋 Checklist complète** : Voir le plan détaillé dans [`building/cycle-01-phase-2-plan.md`](building/cycle-01-phase-2-plan.md)

### ✅ PRÉ-REQUIS (Avant Jour 1)
- [ ] ER Diagram créé (Event → Route, User, Attendance)
- [ ] Branching strategy définie (main/develop/feature branches)
- [ ] Database.yml configuré pour 3 envs (dev/staging/prod)
- [ ] `dbdiagram.md` à jour avec tous les modèles

### ✅ SEMAINE 1 (Jour 1-5) - Setup & Infrastructure
- [ ] Jour 1 : Infrastructure ✓ (déjà fait)
- [ ] Jour 2-3 : Authentification & Rôles
- [ ] Jour 4 : Autorisation & Tests Setup
- [ ] Jour 5 : CI/CD GitHub Actions

### ✅ SEMAINE 2 (Jour 6-10) - CRUD Événements
- [ ] Jour 6-7 : Models CRUD + Tests (TDD) ⚠️ **Routes AVANT Events**
- [ ] Jour 8 : Controllers & Routes
- [ ] Jour 9 : Inscriptions & Calendrier
- [ ] Jour 10 : Tests Unitaires & Intégration (Coverage >70%)

### ✅ SEMAINE 3 (Jour 11-15) - Admin Panel & Finalisation
- [x] Jour 11 : Pundit Policies + Finalisation Modèles (policies + accès sécurisés)
- [x] Jour 12 : Installation ActiveAdmin ⚠️ **APRÈS modèles stables**
- [x] Génération ressources ActiveAdmin : Route, Event, Attendance, OrganizerApplication, Partner, ContactMessage, AuditLog, User, Product, Order
- [ ] Jour 13 : Customisation ActiveAdmin
- [ ] Jour 14 : Tests Admin Panel & Notifications
- [ ] Jour 15 : Performance & Sécurité (Brakeman)

> ℹ️ `bin/docker-entrypoint` reconstruit automatiquement les CSS (application + ActiveAdmin) à chaque `docker compose up web`.  
> Accès back-office validé : http://localhost:3000/admin (`admin@roller.com` / `admin123`).
> Accès admin vérifié : http://localhost:3000/admin (`admin@roller.com` / `admin123`).

---

## 🎯 PROCHAINES ÉTAPES

### ✅ Phase 1 - E-commerce (TERMINÉE)
1. **✅ Validation du fil conducteur**
2. **✅ Création du repository GitHub**
3. **✅ Initialisation du projet Rails 8**
4. **✅ Configuration du tableau Trello**
5. **✅ E-commerce complet**
6. **✅ Documentation complète**

### 🔜 Phase 2 - Événements (15 jours - À VENIR)
1. **🔜 Checklist complète** : Voir le plan détaillé dans [`building/cycle-01-phase-2-plan.md`](building/cycle-01-phase-2-plan.md)
2. **🔜 Développement module événements** (Jour 6-9)
3. **✅ Tests TDD >70% coverage** (Jour 10)
4. **✅ ActiveAdmin** (Jour 12-13)
5. **🔜 Performance & Sécurité** (Jour 15)

---

*Guide créé le : $(date)*  
*Version : 1.0*  
*Équipe : 2 développeurs*
