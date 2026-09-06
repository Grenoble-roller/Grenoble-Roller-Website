# Staging Troubleshooting Guide

**Dernière mise à jour** : 2026-08-14


Common issues and solutions for the staging environment.

## Container Won't Start

### Check if container exists

```bash
docker ps -a | grep staging
```

If the container doesn't appear, it failed during build or startup.

### View build logs

```bash
docker compose -f ops/staging/docker-compose.yml build --no-cache
```

### View container logs

If the container exists but stopped:

```bash
docker logs grenoble-roller-staging
```

### Check docker-compose logs

```bash
docker compose -f ops/staging/docker-compose.yml logs web
docker compose -f ops/staging/docker-compose.yml logs db
```

## Common Errors

### Error: "yarn.lock not found"

**Problem**: The Dockerfile was looking for `yarn.lock` but the project uses npm.

**Solution**: This should be fixed in the current Dockerfile. If you still see this:
1. Make sure you've pulled the latest changes
2. Rebuild without cache: `docker compose -f ops/staging/docker-compose.yml build --no-cache`

### Error: "config/master.key not found"

**Problem**: Rails encrypted credentials require a master key.

**Solution**:
1. Check if `.env` file exists and contains `RAILS_MASTER_KEY`
2. Or copy `config/master.key` from another environment (never commit it)
3. Or regenerate: `bin/rails credentials:edit`

### Error: "Database connection refused"

**Problem**: The web container can't connect to the database.

**Solution**:
1. Check if database container is running: `docker ps | grep grenoble-roller-db-staging`
2. Check database health: `docker exec grenoble-roller-db-staging pg_isready -U postgres`
3. Verify network: Containers should be on the same Docker network
4. Check DATABASE_URL in `.env` file matches docker-compose.yml

### Error: "Port already in use"

**Problem**: Port 3001 is already used by another service.

**Solution**:
1. Find what's using the port: `lsof -i :3001` or `sudo netstat -tulpn | grep 3001`
2. Stop the conflicting service, OR
3. Change port in `ops/staging/docker-compose.yml`:
   ```yaml
   ports:
     - "3002:3000"  # Change 3001 to another port
   ```

### Error: Container exits immediately

**Problem**: The application crashes on startup.

**Solution**:
1. Check logs: `docker logs grenoble-roller-staging`
2. Check if migrations are needed: `docker exec grenoble-roller-staging bin/rails db:migrate:status`
3. Check environment variables: `docker exec grenoble-roller-staging env | grep RAILS`
4. Try running Rails console: `docker exec -it grenoble-roller-staging bin/rails console`

## Health Check Failures

### Health check uses curl

The health check requires `curl` to be installed in the container. This should be included in the Dockerfile base packages.

If health check fails:
1. Verify curl is installed: `docker exec grenoble-roller-staging which curl`
2. Test health endpoint manually: `docker exec grenoble-roller-staging curl -f http://localhost:3000/up`
3. Check if Rails server is running: `docker exec grenoble-roller-staging ps aux | grep rails`

## Database Issues

### Database not accessible

```bash
# Check database container status
docker ps | grep grenoble-roller-db-staging

# Check database logs
docker logs grenoble-roller-db-staging

# Test connection from web container
docker exec grenoble-roller-staging bin/rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
```

### Migrations not run

```bash
# Check migration status
docker exec grenoble-roller-staging bin/rails db:migrate:status

# Run migrations
docker exec grenoble-roller-staging bin/rails db:migrate
```

### Reset database

⚠️ **Warning**: This will delete all data!

```bash
docker exec grenoble-roller-staging bin/rails db:reset
```

## Rebuild Everything

If nothing works, try a complete rebuild:

```bash
# Stop and remove containers
docker compose -f ops/staging/docker-compose.yml down

# Remove volumes (⚠️ deletes data)
docker compose -f ops/staging/docker-compose.yml down -v

# Rebuild without cache
docker compose -f ops/staging/docker-compose.yml build --no-cache

# Start fresh
docker compose -f ops/staging/docker-compose.yml up -d

# Run migrations
docker exec grenoble-roller-staging bin/rails db:migrate

# Seed if needed
docker exec grenoble-roller-staging bin/rails db:seed
```

## Debug Mode

### Run container interactively

```bash
# Override command to get a shell
docker compose -f ops/staging/docker-compose.yml run --rm web bash
```

### Rails console

```bash
docker exec -it grenoble-roller-staging bin/rails console
```

### Check environment

```bash
docker exec grenoble-roller-staging env
docker exec grenoble-roller-staging bin/rails runner "puts Rails.env"
```

## Network Issues

### Containers can't communicate

```bash
# Check network
docker network ls
docker network inspect <network-name>

# Test connectivity from web to db
docker exec grenoble-roller-staging ping db
docker exec grenoble-roller-staging nc -zv db 5432
```

## Performance Issues

### Check resource usage

```bash
docker stats grenoble-roller-staging
docker stats grenoble-roller-db-staging
```

### Check logs size

```bash
docker system df
docker system prune  # Clean up if needed
```

## Getting Help

If you're still stuck:

1. Collect information:
   ```bash
   docker compose -f ops/staging/docker-compose.yml logs > staging-logs.txt
   docker ps -a > containers.txt
   docker images | grep grenoble-roller > images.txt
   ```

2. Check the main documentation:
   - [Staging Setup](staging-setup.md)
   - [Local Development Setup](../../04-rails/setup/local-development.md)

3. Review common Rails errors in logs

