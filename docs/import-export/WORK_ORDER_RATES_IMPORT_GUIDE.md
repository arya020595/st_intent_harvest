# Work Order Rates Import Guide

## Overview

This guide explains how to import and manage Work Order Rates data from CSV files using the rake tasks.

## Table of Contents

- [Quick Start](#quick-start)
- [CSV File Format](#csv-file-format)
- [Available Rake Tasks](#available-rake-tasks)
- [Import Behavior](#import-behavior)
- [Docker Considerations](#docker-considerations)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

---

## Quick Start

### 1. Prepare Your CSV File

Place your CSV file at: `db/master_data/master_data_work_order_rates.csv`

### 2. Run the Import (Docker)

```bash
# Restart Docker to sync file changes
docker compose restart web

# Run the import
docker compose exec web bin/rails work_order_rates:import
```

### 3. Run the Import (Local)

```bash
bin/rails work_order_rates:import
```

---

## CSV File Format

### Required Headers

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
```

### Column Descriptions

| Column                 | Type    | Required      | Description                                                     |
| ---------------------- | ------- | ------------- | --------------------------------------------------------------- |
| `work_order_name`      | String  | **Yes**       | Unique name of the work order (used for matching/updating)      |
| `rate`                 | Decimal | No            | Rate amount (numeric, can be decimal)                           |
| `unit_of_measurement`  | String  | Conditional\* | Unit name (e.g., "Metric ton (M/ton)", "Bag", "Ha")             |
| `work_order_rate_type` | String  | No            | Type: `normal`, `resources`, or `work_days` (default: `normal`) |

\*_Conditional requirement:_

- Required for `normal` and `resources` types
- Optional/ignored for `work_days` type

### Sample CSV

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Harvesting Above 6 Years,42,Metric ton (M/ton),normal
Harvesting Below 6 Years,47.25,Metric ton (M/ton),normal
Manuring 0.5kg/palm,5.25,Bag,normal
Circle and Path Spray,33.6,Ha,normal
Loading and Unloading Seedling,0.4,Palm,normal
```

### Work Order Rate Types

| Type        | Description                                       | Unit Required |
| ----------- | ------------------------------------------------- | ------------- |
| `normal`    | Show all fields (workers + resources + work days) | Yes           |
| `resources` | Show only resource fields                         | Yes           |
| `work_days` | Show only worker details                          | No            |

---

## Available Rake Tasks

### 1. Import Work Order Rates

**Import from default location:**

```bash
docker compose exec web bin/rails work_order_rates:import
```

**Import from custom file:**

```bash
docker compose exec web bin/rails work_order_rates:import[path/to/custom.csv]
```

**What it does:**

- Creates new work order rates
- Updates existing work order rates (matched by `work_order_name`)
- Auto-creates missing units
- Validates all data
- Runs in a transaction (rolls back on errors)

### 2. List All Work Order Rates

```bash
docker compose exec web bin/rails work_order_rates:list
```

**Output example:**

```
================================================================================
Work Order Rates:
================================================================================

NORMAL:
  • Harvesting Above 6 Years                  | 42.0 Metric ton (M/ton)
  • Manuring 0.5kg/palm                       | 5.25 Bag
  • Circle and Path Spray                     | 33.6 Ha

38 total work order rates
```

### 3. Show Sample CSV Format

```bash
docker compose exec web bin/rails work_order_rates:sample
```

### 4. Delete All Work Order Rates

```bash
docker compose exec web bin/rails work_order_rates:delete_all
```

**⚠️ Warning:** This is destructive! It will prompt for confirmation.

---

## Import Behavior

### Upsert Logic (Create or Update)

The import uses **upsert** logic based on `work_order_name`:

- **If `work_order_name` exists** → Updates the existing record
- **If `work_order_name` is new** → Creates a new record

**Example:**

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Harvesting Above 6 Years,42,Metric ton (M/ton),normal
```

**First import:**

```
✓ Created: Harvesting Above 6 Years (42.0 Metric ton (M/ton)) [normal]
```

**Second import (same CSV):**

```
✓ Updated: Harvesting Above 6 Years (42.0 Metric ton (M/ton)) [normal]
```

**Second import (changed rate to 45):**

```
✓ Updated: Harvesting Above 6 Years (45.0 Metric ton (M/ton)) [normal]
```

### Unit Auto-Creation

If a unit doesn't exist in the database, it will be automatically created:

```
✓ Created new unit: Metric ton (M/ton)
✓ Created: Harvesting Above 6 Years (42.0 Metric ton (M/ton)) [normal]
```

### Transaction Safety

All imports run in a database transaction:

- ✅ **Success:** All changes committed
- ❌ **Error:** All changes rolled back

### Import Statistics

After each import, you'll see a summary:

```
================================================================================
Import Summary:
  Total rows processed: 31
  Created: 5
  Updated: 25
  Skipped: 1
  Errors: 0
  New units created: 2
================================================================================

✓ Import completed successfully!
```

---

## Docker Considerations

### ⚠️ Important: File Synchronization

When using Docker, CSV file changes **may not immediately sync** to the container.

**Problem:**

```bash
# You edit the CSV locally
nano db/master_data/master_data_work_order_rates.csv

# Run import - but Docker sees old version!
docker compose exec web bin/rails work_order_rates:import
# Result: Doesn't process new rows
```

**Solution:**

**Always restart Docker after editing CSV files:**

```bash
# Option 1: Restart web service
docker compose restart web

# Option 2: Full restart (if problems persist)
docker compose down && docker compose up -d

# Then run import
docker compose exec web bin/rails work_order_rates:import
```

### Verify File Sync

Check if Docker sees your latest changes:

```bash
# Count lines in Docker container
docker compose exec web wc -l db/master_data/master_data_work_order_rates.csv

# Count lines locally
wc -l db/master_data/master_data_work_order_rates.csv

# Should match! If not, restart Docker
```

---

## Troubleshooting

### Problem: "Always showing Updated, never Created"

**Cause:** The `work_order_name` already exists in the database.

**Solution:** This is expected behavior (upsert). To create new records, use unique names.

**Check existing names:**

```bash
docker compose exec web bin/rails runner "puts WorkOrderRate.pluck(:work_order_name).sort"
```

### Problem: "New rows not being imported"

**Cause:** Docker volume not synced.

**Solution:**

```bash
docker compose restart web
docker compose exec web bin/rails work_order_rates:import
```

### Problem: "Error: File not found"

**Cause:** CSV file not at expected location.

**Solution:**

```bash
# Check file exists
ls -la db/master_data/master_data_work_order_rates.csv

# Or specify custom path
docker compose exec web bin/rails work_order_rates:import[path/to/file.csv]
```

### Problem: "Invalid work_order_rate_type"

**Error message:**

```
⚠ Row 5: Invalid work_order_rate_type 'custom' for 'Harvesting'
  Valid types: normal, resources, work_days
```

**Solution:** Use only valid types: `normal`, `resources`, or `work_days`.

### Problem: "Validation errors"

**Error message:**

```
✗ Error on row 10 (Harvesting): Validation failed: Unit must exist
```

**Common causes:**

- Missing `unit_of_measurement` for `normal` or `resources` type
- Blank `work_order_name`
- Invalid rate (negative number)

**Solution:** Fix the CSV data and re-import.

---

## Examples

### Example 1: First-Time Import

**CSV file (`db/master_data/master_data_work_order_rates.csv`):**

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Harvesting,42,Metric ton (M/ton),normal
Planting,2,Palm,normal
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails work_order_rates:import
```

**Output:**

```
Starting import from: /rails/db/master_data/master_data_work_order_rates.csv
================================================================================
  ✓ Created new unit: Metric ton (M/ton)
✓ Created: Harvesting (42.0 Metric ton (M/ton)) [normal]
  ✓ Created new unit: Palm
✓ Created: Planting (2.0 Palm) [normal]
================================================================================
Import Summary:
  Total rows processed: 2
  Created: 2
  Updated: 0
  Skipped: 0
  Errors: 0
  New units created: 2
================================================================================

✓ Import completed successfully!
```

### Example 2: Update Existing Rates

**Modified CSV (changed Harvesting rate from 42 to 45):**

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Harvesting,45,Metric ton (M/ton),normal
Planting,2,Palm,normal
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails work_order_rates:import
```

**Output:**

```
✓ Updated: Harvesting (45.0 Metric ton (M/ton)) [normal]
✓ Updated: Planting (2.0 Palm) [normal]
================================================================================
Import Summary:
  Total rows processed: 2
  Created: 0
  Updated: 2
  Skipped: 0
  Errors: 0
  New units created: 0
================================================================================
```

### Example 3: Adding New Rows

**CSV with new row added:**

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Harvesting,45,Metric ton (M/ton),normal
Planting,2,Palm,normal
Fertilizing,5.25,Bag,normal
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails work_order_rates:import
```

**Output:**

```
✓ Updated: Harvesting (45.0 Metric ton (M/ton)) [normal]
✓ Updated: Planting (2.0 Palm) [normal]
  ✓ Created new unit: Bag
✓ Created: Fertilizing (5.25 Bag) [normal]
================================================================================
Import Summary:
  Total rows processed: 3
  Created: 1
  Updated: 2
  Skipped: 0
  Errors: 0
  New units created: 1
================================================================================
```

### Example 4: work_days Type (No Unit Required)

**CSV:**

```csv
work_order_name,rate,unit_of_measurement,work_order_rate_type
Daily Worker Rate,75,,work_days
```

**Output:**

```
✓ Created: Daily Worker Rate (75.0 N/A) [work_days]
```

Note: `unit_of_measurement` is ignored for `work_days` type.

---

## Best Practices

### 1. Always Backup Before Import

```bash
# Export current data
docker compose exec web bin/rails runner "
  require 'csv'
  CSV.open('backup.csv', 'w') do |csv|
    csv << ['work_order_name', 'rate', 'unit_of_measurement', 'work_order_rate_type']
    WorkOrderRate.includes(:unit).find_each do |wor|
      csv << [wor.work_order_name, wor.rate, wor.unit&.name, wor.work_order_rate_type]
    end
  end
"
```

### 2. Test with Sample Data First

Create a small test CSV and verify import works before using full dataset.

### 3. Use Version Control

Commit your CSV files to Git:

```bash
git add db/master_data/master_data_work_order_rates.csv
git commit -m "Update work order rates"
```

### 4. Document Changes

Add comments in commit messages explaining rate changes.

### 5. Restart Docker After CSV Changes

**Always remember:**

```bash
docker compose restart web  # ← Don't forget this!
docker compose exec web bin/rails work_order_rates:import
```

---

## Advanced Usage

### Import from Different Location

```bash
docker compose exec web bin/rails work_order_rates:import[db/custom_rates.csv]
```

### Programmatic Import

```ruby
# In Rails console or script
importer = WorkOrderRatesImporter.new('path/to/file.csv')
importer.import
```

### Check Before Import

```bash
# List current rates
docker compose exec web bin/rails work_order_rates:list

# Import
docker compose exec web bin/rails work_order_rates:import

# Verify changes
docker compose exec web bin/rails work_order_rates:list
```

---

## Related Documentation

- [Work Order Rate Model](../app/models/work_order_rate.rb)
- [Unit Model](../app/models/unit.rb)
- [Import Task Source](../lib/tasks/import_work_order_rates.rake)

---

## Support

If you encounter issues not covered in this guide:

1. Check the error message in the import output
2. Verify CSV format matches the sample
3. Ensure Docker is restarted after file changes
4. Check database validations in `app/models/work_order_rate.rb`

For questions, contact the development team.
