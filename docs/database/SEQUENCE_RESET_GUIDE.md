# Database Sequence Reset Prevention

## Problem

PostgreSQL sequences can become out of sync with actual table data, causing `PG::UniqueViolation: duplicate key` errors when inserting new records. This happens when:

- Database is restored from backups
- Records are inserted via raw SQL instead of Rails
- Migrations are rolled back
- Manual data imports occur

## Solution

We now have an automated rake task that resets all PostgreSQL sequences after every deployment.

### How it works

**Rake Task:** `lib/tasks/db.rake`

```bash
rails db:reset_sequences
```

This task:

1. Identifies all tables with serial primary keys
2. Finds the maximum ID in each table
3. Resets the sequence counter to `MAX(id) + 1`
4. Prevents future duplicate key violations

**Deployment Integration:**
The workflow automatically runs this after every migration:

```yaml
docker compose exec -T web rails db:migrate
docker compose exec -T web rails db:reset_sequences
```

### Manual usage

If you need to reset sequences without deploying:

```bash
# On production server
cd ~/st_intent_harvest  # or ~/st_accorn
docker compose exec web rails db:reset_sequences

# Or with just the database:
docker compose exec db psql -U postgres -d your_database_name -c \
  "SELECT setval('table_name_id_seq', COALESCE((SELECT MAX(id) FROM table_name), 1) + 1);"
```

### Monitoring

Watch for these errors in logs:

```
PG::UniqueViolation: ERROR: duplicate key value violates unique constraint
DETAIL: Key (id)=(...) already exists.
```

If this occurs, run the rake task immediately.

### Testing locally

```bash
# Development
./bin/rails db:reset_sequences

# Test environment
./bin/rails db:reset_sequences RAILS_ENV=test
```
