
# Grenoble Roller – Community Platform

**Repository**: [https://github.com/FlowTech-Lab/Grenoble-Roller-Project](https://github.com/FlowTech-Lab/Grenoble-Roller-Project)

### Short Description
Community platform for the Grenoble rollerblading association, featuring an e-commerce shop for goodies and future event management capabilities.

## Overview
A Ruby on Rails 8 web application for the Grenoble rollerblading community. Currently implements a complete e-commerce shop with product catalog, shopping cart, and order management. Event management features are planned for future development.

## Goals
- Bring the Grenoble roller community together
- Provide an e-commerce platform for association goodies
- Enable future event creation and discovery (Phase 2)
- Highlight predefined routes with maps (Phase 2)

## Current Status (Phase 1 - E-commerce)

### ✅ Implemented Features
- **Authentication & Authorization**
  - Devise-based user authentication
  - 7-level role system (USER, REGISTERED, INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
  - User profiles with personal information
  - Password reset functionality

- **E-commerce Shop**
  - Product catalog with categories (Rollers, Protections, Accessoires)
  - Product variants with options (size, color)
  - Shopping cart functionality
  - Order management system
  - Payment integration structure (ready for HelloAsso/Stripe/PayPal)
  - Stock management

- **Pages**
  - Homepage
  - Association information page
  - Product listing and detail pages

### 🚧 Planned Features (Phase 2)
- Event creation and management
- Event listing with calendar view
- Route maps integration
- Verified organizer system
- Member-submitted outing ideas

## Roles & Permissions
- **USER** (level 10): Basic user, can browse and purchase
- **REGISTERED** (level 20): Registered member
- **INITIATION** (level 30): Initiation level member
- **ORGANIZER** (level 40): Can create and manage events (future)
- **MODERATOR** (level 50): Can moderate content (future)
- **ADMIN** (level 60): Full administrative access
- **SUPERADMIN** (level 70): Highest level access

## Tech Stack
- **Framework**: Ruby on Rails 8.0.4
- **Database**: PostgreSQL 16
- **Authentication**: Devise
- **Frontend**: Bootstrap 5, Stimulus, Turbo
- **Containerization**: Docker & Docker Compose
- **Deployment**: Kamal-ready (Dockerfile included)

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Git

### Development Setup

```bash
# Clone the repository
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project

# Start Docker containers
docker compose -f ops/dev/docker-compose.yml up -d --build

# Run database migrations and seed
docker exec grenoble-roller-dev bin/rails db:migrate
docker exec grenoble-roller-dev bin/rails db:seed
```

**Access the application**
- Application: http://localhost:3000
- Database: localhost:5434 (user: postgres, password: postgres)

### Default Test Accounts
- **Super Admin**: `T3rorX@hotmail.fr` / `T3rorX123`
- **Admin**: `admin@roller.com` / `admin123`
- **Test Users**: `client1@example.com` to `client5@example.com` / `password123`

## 📁 Project Structure

```
├── app/
│   ├── controllers/     # Application controllers
│   ├── models/          # ActiveRecord models
│   ├── views/           # ERB templates
│   └── assets/          # CSS, JS, images
├── config/
│   ├── credentials.yml.enc  # Encrypted secrets (requires master.key)
│   └── environments/   # Environment configurations
├── db/
│   ├── migrate/         # Database migrations
│   ├── seeds.rb         # Seed data
│   └── schema.rb        # Current database schema
├── docs/                # Project documentation
├── ops/                 # Docker Compose configurations
│   ├── dev/            # Development environment
│   ├── staging/        # Staging environment
│   └── production/      # Production environment
└── ressources/          # Design resources, guides
```

## 🔐 Security & Credentials

The project uses Rails encrypted credentials. The `config/master.key` file is required to decrypt `config/credentials.yml.enc`.

**Important**: 
- `config/master.key` is in `.gitignore` (never commit it)
- `config/credentials.yml.enc` can be committed (it's encrypted)
- If you need to regenerate credentials: `bin/rails credentials:edit`

## 🎯 Méthodologie Shape Up

**Appetite fixe (6 semaines), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

### 4 Phases Shape Up
1. **SHAPING** (Semaine -2 à 0) : Définir les limites
2. **BETTING TABLE** (Semaine 0) : Priorisation brutale  
3. **BUILDING** (Semaine 1-6) : Livrer feature shippable
4. **COOLDOWN** (Semaine 7-8) : Repos obligatoire

### Rabbit Holes Évités
- ❌ Microservices → Monolithe Rails d'abord
- ❌ Kubernetes → Docker Compose simple
- ❌ Internationalisation → MVP français uniquement
- ❌ API publique → API interne uniquement

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:
- Architecture and design decisions
- Rails conventions and setup guides
- Testing strategies
- Operations runbooks
- Security and privacy guidelines

See `docs/README.md` for the complete documentation index.

## 🗄️ Database Schema

### Core Models
- **Users**: Authentication and user profiles (Devise)
- **Roles**: 7-level permission system
- **Products**: Product catalog with categories
- **ProductVariants**: Product variations with options (size, color)
- **Orders**: Customer orders
- **OrderItems**: Order line items
- **Payments**: Payment records (multi-provider ready)

See `db/schema.rb` for the complete database structure.

## 🐳 Docker Environments

Three Docker Compose configurations are available:

- **Development** (`ops/dev/`): Port 3000, hot-reload enabled
- **Staging** (`ops/staging/`): Port 3001, production-like
- **Production** (`ops/production/`): Port 3002, optimized build

## 🔄 Future Enhancements (Backlog)
- Event creation and management system
- Route maps with GPX integration
- Email notifications
- Advanced search and filtering
- Payment gateway integration (HelloAsso, Stripe, PayPal)
- Social features (sharing, comments)
