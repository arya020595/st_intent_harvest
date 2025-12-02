# Blocks Import Guide

## Overview

This guide explains how to import and manage Blocks data from CSV files using the rake tasks.

## Quick Start

### 1. Prepare Your CSV File

Place your CSV file at: `db/master_data/master_data_bloks .csv`

**Note:** The filename has a space before `.csv` - this is intentional to match the existing file.

### 2. Run the Import (Docker)

```bash
# Restart Docker to sync file changes
docker compose restart web

# Run the import
docker compose exec web bin/rails blocks:import
```

### 3. Run the Import (Local)

```bash
bin/rails blocks:import
```

---

## CSV File Format

### Required Headers

```csv
block_number,hectarage
```

### Column Descriptions

| Column         | Type    | Required | Description                                 |
| -------------- | ------- | -------- | ------------------------------------------- |
| `block_number` | String  | **Yes**  | Unique block identifier (e.g., A1, B2, C3)  |
| `hectarage`    | Decimal | **Yes**  | Size of the block in hectares (must be > 0) |

### Sample CSV

```csv
block_number,hectarage
A1,24.79
A2,20.57
A3,21.43
B1,19.72
B2,25.72
C1,14.08
C2,14.72
```

### Important Notes

- ⚠️ **Block numbers are case-sensitive**: `A1` ≠ `a1`
- ✅ **Hectarage must be positive**: Cannot be zero or negative
- 🔄 **Upsert behavior**: Existing blocks (matched by `block_number`) will be updated

---

## Available Rake Tasks

### 1. Import Blocks

**Import from default location:**

```bash
docker compose exec web bin/rails blocks:import
```

**Import from custom file:**

```bash
docker compose exec web bin/rails blocks:import[path/to/custom.csv]
```

**What it does:**

- Creates new blocks
- Updates existing blocks (matched by `block_number`)
- Validates all data
- Runs in a transaction (rolls back on errors)

### 2. List All Blocks

```bash
docker compose exec web bin/rails blocks:list
```

**Output example:**

```
================================================================================
Blocks:
================================================================================
  • A1              | 24.79 Ha
  • A2              | 20.57 Ha
  • A3              | 21.43 Ha
  • B1              | 19.72 Ha
  • B2              | 25.72 Ha

53 total blocks | Total hectarage: 1052.17 Ha
```

### 3. Show Sample CSV Format

```bash
docker compose exec web bin/rails blocks:sample
```

### 4. Delete All Blocks

```bash
docker compose exec web bin/rails blocks:delete_all
```

**⚠️ Warning:** This is destructive! It will prompt for confirmation.

---

## Import Behavior

### Upsert Logic (Create or Update)

The import uses **upsert** logic based on `block_number`:

- **If `block_number` exists** → Updates the existing record
- **If `block_number` is new** → Creates a new record

**Example:**

```csv
block_number,hectarage
A1,24.79
```

**First import:**

```
✓ Created: A1 (24.79 Ha)
```

**Second import (same CSV):**

```
✓ Updated: A1 (24.79 Ha)
```

**Second import (changed hectarage to 30.5):**

```
✓ Updated: A1 (30.5 Ha)
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
  Total rows processed: 43
  Created: 40
  Updated: 3
  Skipped: 0
  Errors: 0
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
nano "db/master_data/master_data_bloks .csv"

# Run import - but Docker sees old version!
docker compose exec web bin/rails blocks:import
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
docker compose exec web bin/rails blocks:import
```

### Verify File Sync

Check if Docker sees your latest changes:

```bash
# Count lines in Docker container
docker compose exec web wc -l "db/master_data/master_data_bloks .csv"

# Count lines locally
wc -l "db/master_data/master_data_bloks .csv"

# Should match! If not, restart Docker
```

---

## Troubleshooting

### Problem: "Always showing Updated, never Created"

**Cause:** The `block_number` already exists in the database.

**Solution:** This is expected behavior (upsert). To create new records, use unique block numbers.

**Check existing block numbers:**

```bash
docker compose exec web bin/rails runner "puts Block.pluck(:block_number).sort"
```

### Problem: "New rows not being imported"

**Cause:** Docker volume not synced.

**Solution:**

```bash
docker compose restart web
docker compose exec web bin/rails blocks:import
```

### Problem: "Error: File not found"

**Cause:** CSV file not at expected location.

**Solution:**

```bash
# Check file exists (note the space before .csv)
ls -la "db/master_data/master_data_bloks .csv"

# Or specify custom path
docker compose exec web bin/rails blocks:import[path/to/file.csv]
```

### Problem: "Validation failed: Block number has already been taken"

**Error message:**

```
✗ Error on row 5 (A1): Validation failed: Block number has already been taken
```

**Cause:** Duplicate `block_number` in CSV file.

**Solution:** Remove duplicate rows or use different block numbers.

### Problem: "Validation failed: Hectarage must be greater than 0"

**Error message:**

```
✗ Error on row 10 (G6): Validation failed: Hectarage must be greater than 0
```

**Cause:** Hectarage is zero or negative.

**Solution:** Fix the CSV data with positive hectarage values.

---

## Examples

### Example 1: First-Time Import

**CSV file (`db/master_data/master_data_bloks .csv`):**

```csv
block_number,hectarage
A1,24.79
A2,20.57
B1,19.72
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails blocks:import
```

**Output:**

```
Starting import from: /rails/db/master_data/master_data_bloks .csv
================================================================================
✓ Created: A1 (24.79 Ha)
✓ Created: A2 (20.57 Ha)
✓ Created: B1 (19.72 Ha)
================================================================================
Import Summary:
  Total rows processed: 3
  Created: 3
  Updated: 0
  Skipped: 0
  Errors: 0
================================================================================

✓ Import completed successfully!
```

### Example 2: Update Existing Blocks

**Modified CSV (changed A1 hectarage from 24.79 to 30.0):**

```csv
block_number,hectarage
A1,30.0
A2,20.57
B1,19.72
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails blocks:import
```

**Output:**

```
✓ Updated: A1 (30.0 Ha)
✓ Updated: A2 (20.57 Ha)
✓ Updated: B1 (19.72 Ha)
================================================================================
Import Summary:
  Total rows processed: 3
  Created: 0
  Updated: 3
  Skipped: 0
  Errors: 0
================================================================================
```

### Example 3: Adding New Blocks

**CSV with new block added:**

```csv
block_number,hectarage
A1,30.0
A2,20.57
B1,19.72
C1,14.08
```

**Commands:**

```bash
docker compose restart web
docker compose exec web bin/rails blocks:import
```

**Output:**

```
✓ Updated: A1 (30.0 Ha)
✓ Updated: A2 (20.57 Ha)
✓ Updated: B1 (19.72 Ha)
✓ Created: C1 (14.08 Ha)
================================================================================
Import Summary:
  Total rows processed: 4
  Created: 1
  Updated: 3
  Skipped: 0
  Errors: 0
================================================================================
```

### Example 4: Handling Errors

**CSV with invalid data:**

```csv
block_number,hectarage
A1,24.79
,20.57
B1,-5.0
```

**Output:**

```
✓ Updated: A1 (24.79 Ha)
⚠ Row 2: Skipping - block_number is blank
✗ Error on row 3 (B1): Validation failed: Hectarage must be greater than 0
================================================================================
Import Summary:
  Total rows processed: 3
  Created: 0
  Updated: 1
  Skipped: 1
  Errors: 1
================================================================================

⚠ Import completed with errors. Review the output above.
```

---

## Best Practices

### 1. Always Backup Before Import

```bash
# Export current data
docker compose exec web bin/rails runner "
  require 'csv'
  CSV.open('blocks_backup.csv', 'w') do |csv|
    csv << ['block_number', 'hectarage']
    Block.order(:block_number).find_each do |block|
      csv << [block.block_number, block.hectarage]
    end
  end
"
```

### 2. Test with Sample Data First

Create a small test CSV and verify import works before using full dataset.

### 3. Use Version Control

Commit your CSV files to Git:

```bash
git add "db/master_data/master_data_bloks .csv"
git commit -m "Update blocks data"
```

### 4. Document Changes

Add comments in commit messages explaining hectarage changes.

### 5. Restart Docker After CSV Changes

**Always remember:**

```bash
docker compose restart web  # ← Don't forget this!
docker compose exec web bin/rails blocks:import
```

### 6. Verify Total Hectarage

After import, check total hectarage makes sense:

```bash
docker compose exec web bin/rails blocks:list
# Look at: "Total hectarage: X Ha"
```

---

## Advanced Usage

### Import from Different Location

```bash
docker compose exec web bin/rails blocks:import[db/custom_blocks.csv]
```

### Programmatic Import

```ruby
# In Rails console or script
importer = BlocksImporter.new('path/to/file.csv')
importer.import
```

### Check Before Import

```bash
# List current blocks
docker compose exec web bin/rails blocks:list

# Import
docker compose exec web bin/rails blocks:import

# Verify changes
docker compose exec web bin/rails blocks:list
```

### Calculate Total Area

```bash
docker compose exec web bin/rails runner "
  total = Block.sum(:hectarage)
  puts \"Total plantation area: #{total.round(2)} Ha\"
"
```

---

## Data Validation Rules

| Rule                   | Description                        | Example                   |
| ---------------------- | ---------------------------------- | ------------------------- |
| **Uniqueness**         | Each `block_number` must be unique | Cannot have two A1 blocks |
| **Presence**           | `block_number` is required         | Cannot be blank or null   |
| **Positive Hectarage** | `hectarage` must be > 0            | Cannot be 0 or negative   |
| **Case Sensitivity**   | `A1` ≠ `a1` ≠ `A01`                | Use consistent naming     |

---

## Integration with Work Orders

Blocks are linked to Work Orders. Before deleting blocks:

**Check if block has work orders:**

```bash
docker compose exec web bin/rails runner "
  block = Block.find_by(block_number: 'A1')
  if block.work_orders.any?
    puts 'Block A1 has #{block.work_orders.count} work orders'
  else
    puts 'Block A1 has no work orders'
  end
"
```

**Note:** Deleting a block will set `block_id` to NULL in associated work orders (due to `dependent: :nullify`).

---

## Related Documentation

- [Block Model](../app/models/block.rb)
- [Import Task Source](../lib/tasks/import_blocks.rake)
- [Work Order Rates Import Guide](WORK_ORDER_RATES_IMPORT_GUIDE.md)

---

## Support

If you encounter issues not covered in this guide:

1. Check the error message in the import output
2. Verify CSV format matches the sample
3. Ensure Docker is restarted after file changes
4. Check database validations in `app/models/block.rb`
5. Verify block_number uniqueness

For questions, contact the development team.
