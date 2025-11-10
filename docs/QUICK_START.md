# 🚀 Quick Start Guide

## First Time Setup (5 minutes)

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Build Docker images (takes 5-10 minutes first time)
docker compose build

# 3. Start all services
docker compose up -d

# 4. Setup database
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# 5. Open your browser
# Visit: http://localhost:3000
# Login: admin@example.com / password123
```

## Daily Workflow

```bash
# Start work
docker compose up -d

# Stop work
docker compose down

# View logs
docker compose logs -f web
```

## Common Commands

### No `bundle exec` needed! 🎉

```bash
# Run migrations
docker compose exec web rails db:migrate

# Open Rails console
docker compose exec web rails console

# Run tests
docker compose exec web rails test

# Generate migration
docker compose exec web rails generate migration AddColumnToUsers

# View routes
docker compose exec web rails routes

# Install new gems (after updating Gemfile)
docker compose exec web bundle install

# Open bash terminal
docker compose exec web bash
```

## Troubleshooting

### Port already in use?

```bash
# PostgreSQL (5432)
sudo systemctl stop postgresql

# Redis (6379)
sudo systemctl stop redis-server

# Or change ports in docker-compose.yml to 5433:5432 and 6380:6379
```

### Database connection error?

```bash
# Restart services
docker compose restart web

# Check database is running
docker compose exec db psql -U postgres -c "SELECT version();"
```

### Code changes not reflecting?

- No restart needed! Volume mounts sync code in real-time.
- For gem changes: Just restart the container `docker compose restart web`

### New gem added - "Run `bundle install` to install missing gems"?

This happens when someone added a new gem and you pulled their changes.

**Solution: Just restart the container** 🎉

```bash
# The entrypoint automatically runs bundle install on startup
docker compose restart web

# Or if you want to see the bundle install output:
docker compose down
docker compose up -d
docker compose logs -f web
```

**How this works:**

- Your `docker-compose.yml` uses a persistent `bundle_cache` volume (line 56)
- Gems are stored in this volume, not in the image
- The entrypoint runs `bundle check || bundle install` on every startup
- New gems are installed automatically without rebuilding!

**If container is stuck restarting:**

```bash
# Check logs first to see the error
docker compose logs web

# Force restart
docker compose down
docker compose up -d
```

**Prevention for team:**
When you add a new gem, mention in PR/commit message:

> "Added new gem - teammates need to restart: `docker compose restart web`"

### Reset everything?

```bash
docker compose down -v  # Remove containers and volumes
docker compose build    # Rebuild images
docker compose up -d    # Start fresh
```

## 📚 Documentation

- **[DOCKER_GUIDE.md](./DOCKER_GUIDE.md)** - Comprehensive Docker documentation
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🆘 Need Help?

Having issues? Check the **[Troubleshooting Guide](./TROUBLESHOOTING.md)** for:

- Images not rendering or updating
- Container startup problems
- Database connection issues
- Gem installation errors
- Performance problems
- And more...
