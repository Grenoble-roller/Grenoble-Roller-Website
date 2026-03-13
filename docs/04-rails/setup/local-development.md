# Local Development Setup

This guide explains how to set up the Grenoble Roller project for local development using Docker.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- Ruby 3.4.2 (via Docker)
- Rails 8.1.1 (via Docker)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
```

### 2. Configure Credentials

The project uses Rails encrypted credentials. If you don't have `config/master.key`:

```bash
# This will create a new master.key and credentials.yml.enc
bin/rails credentials:edit
```

**Note**: If you're working in a team, ask for the `master.key` file (it's not in git for security reasons).

### 3. Start Docker Containers

```bash
docker compose -f ops/dev/docker-compose.yml up -d
```

This will:
- Build the Rails application container
- Start PostgreSQL database
- Start CSS watcher for automatic CSS recompilation
- Expose the app on http://localhost:3000
- Expose the database on localhost:5434

### 4. Install Dependencies and Initialize Database

```bash
# Install gems (required for first setup)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle install

# Run migrations
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:migrate

# Seed the database with test data
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:seed
```

**Note**: The `BUNDLE_PATH=/rails/vendor/bundle` environment variable is required for Docker Compose to properly install gems in the shared volume.

### 5. Access the Application

- **Application**: http://localhost:3000
- **Database**: localhost:5434
  - User: `postgres`
  - Password: `postgres`
  - Database: `grenoble_roller_development`

## Default Test Accounts

After running `db:seed`, you can log in with:

- **Super Admin**: `T3rorX@hotmail.fr` / `T3rorX123`
- **Admin**: `admin@roller.com` / `admin123`
- **Test Users**: `client1@example.com` to `client5@example.com` / `password123`

## Development Workflow

### View Logs

```bash
# Application logs
docker logs -f grenoble-roller-dev

# Database logs
docker logs -f grenoble-roller-db-dev
```

### Run Rails Commands

```bash
# Rails console
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails console

# Run migrations
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:migrate

# Run tests (RSpec)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec

# Generate a new model/controller
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails generate model Product name:string
```

### Stop Containers

```bash
docker compose -f ops/dev/docker-compose.yml down
```

### Reset Database

```bash
# Drop, create, migrate, and seed
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:reset
```

### Clean Rebuild (Fresh Start)

If you need to completely rebuild the environment from scratch:

```bash
# Stop and remove all containers and volumes
docker compose -f ops/dev/docker-compose.yml down --volumes

# Rebuild containers (no cache)
docker compose -f ops/dev/docker-compose.yml build --no-cache web

# Start database
docker compose -f ops/dev/docker-compose.yml up -d db

# Install gems
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle install

# Setup database (create, migrate, seed)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:setup

# Setup test database
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bash -lc "bundle exec rails db:drop db:create db:schema:load"

# Start application
docker compose -f ops/dev/docker-compose.yml up web
```

## CSS Auto-Reload

The development environment includes automatic CSS recompilation:

- **CSS Watcher**: A separate container (`grenoble-roller-css-watcher`) watches for changes in `app/assets/stylesheets/` and automatically recompiles CSS
- **Auto-rebuild on startup**: CSS is automatically rebuilt when containers start, ensuring latest changes after `git pull`
- **No manual rebuild needed**: Just save your SCSS files and refresh the browser

### After Git Pull

When you pull changes that include CSS modifications:

1. The CSS will be automatically rebuilt on container startup
2. The CSS watcher will continue monitoring for new changes
3. No need to manually run `npm run build:css`

### Manual CSS Rebuild

If needed, you can manually rebuild CSS:

```bash
# Rebuild CSS once
docker exec grenoble-roller-dev npm run build:css

# Check CSS watcher logs
docker logs -f grenoble-roller-css-watcher
```

## Assets Management (Bootstrap & Bootstrap Icons)

The project uses Bootstrap 5.3.2 and Bootstrap Icons via npm and Rails Importmap. After a clean rebuild, you may need to restore the assets:

### Bootstrap JavaScript

Bootstrap JS is managed via Rails Importmap. The bundle file should be in `vendor/javascript/`:

```bash
# If missing after rebuild, copy from node_modules
cp node_modules/bootstrap/dist/js/bootstrap.bundle.min.js vendor/javascript/bootstrap.bundle.min.js
```

### Bootstrap Icons Fonts

Bootstrap Icons fonts need to be copied to the assets builds directory:

```bash
# Create fonts directory if missing
mkdir -p app/assets/builds/fonts

# Copy Bootstrap Icons fonts
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2 app/assets/builds/fonts/bootstrap-icons.woff2
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff app/assets/builds/fonts/bootstrap-icons.woff

# Rebuild CSS to ensure fonts are properly referenced
npm run build:css
```

**Note**: These assets are included in the Docker build process, but may need to be restored after a local clean rebuild.

## Docker Compose Configuration

The development environment is configured in `ops/dev/docker-compose.yml`:

- **Web container**: `grenoble-roller-dev` (port 3000)
- **CSS Watcher container**: `grenoble-roller-css-watcher` (watches SCSS files)
- **Database container**: `grenoble-roller-db-dev` (port 5434)
- **Volumes**: Code is mounted for hot-reload
- **Health checks**: Automatic container health monitoring

## Troubleshooting

### Container won't start

```bash
# Check container status
docker ps -a

# View container logs
docker logs grenoble-roller-dev

# Rebuild containers
docker compose -f ops/dev/docker-compose.yml up -d --build
```

### Database connection errors

```bash
# Check if database is healthy
docker exec grenoble-roller-db-dev pg_isready -U postgres

# Restart database
docker compose -f ops/dev/docker-compose.yml restart db
```

### Credentials errors

If you see "Missing 'config/master.key' to decrypt credentials":

1. Check if `config/master.key` exists
2. If not, regenerate: `bin/rails credentials:edit`
3. Or ask a team member for the key

### Port already in use

If port 3000 or 5434 is already in use:

1. Stop the conflicting service
2. Or modify ports in `ops/dev/docker-compose.yml`

## Next Steps

- Read the [Rails conventions](../conventions/)
- Check the [architecture documentation](../../03-architecture/)
- Review the [testing strategy](../../05-testing/)
