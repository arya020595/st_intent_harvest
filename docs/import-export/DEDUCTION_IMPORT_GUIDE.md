# Deduction Management Import System

## Overview

This system manages statutory deductions (EPF, SOCSO, EIS, SIP) for payroll calculations using a **wage range-based approach** instead of percentage calculations. The import system allows you to manage deduction types and their wage range tables via CSV files and Rake tasks.

## Core Concepts

### 1. Deduction Types

Deduction types define the **metadata** for each statutory deduction:

- **Code**: Unique identifier (e.g., `EPF_LOCAL`, `SOCSO`)
- **Name**: Display name
- **Calculation Type**: `percentage`, `fixed`, or `wage_range`
  - `percentage`: Uses employee/employer contribution rates (e.g., EPF Foreign: 11%/12%)
  - `fixed`: Uses fixed amounts directly from deduction_type table
  - `wage_range`: Uses wage range tables with fixed amounts (e.g., EPF Local, SOCSO, EIS)
- **Nationality**: Applies to `all`, `local`, `foreigner`, or `foreigner_no_passport`
- **Effective Dates**: Version control with `effective_from` and `effective_until`
- **Active Status**: `is_active` flag to enable/disable deductions

### 2. Wage Ranges

For `wage_range` calculation type deductions, wage ranges define the **actual deduction amounts** based on salary bands:

- **Salary Range**: `min_wage` to `max_wage` (NULL for open-ended ranges)
- **Fixed Amounts**: `employee_amount` and `employer_amount`
- **Calculation Method**: Always `fixed` for wage range tables

**Example:**

```
Salary RM 1,000 - RM 1,050 → Employee: RM 22, Employer: RM 40
Salary RM 5,000+            → Employee: RM 550, Employer: RM 600
```

## File Structure

```
db/master_data/master_data_deductions/
├── deduction_types.csv           # Master list of deduction types
├── epf_local_wage_ranges.csv     # EPF Local wage ranges (100 rows)
├── socso_wage_ranges.csv         # SOCSO ranges for all workers (65 rows)
└── eis_local_wage_ranges.csv     # EIS Local ranges (60 rows)
```

## CSV Formats

### deduction_types.csv

```csv
code,name,calculation_type,employee_contribution,employer_contribution,nationality,effective_from,effective_until,is_active,description
EPF_LOCAL,EPF Local,wage_range,0,0,local,2025-01-01,,true,EPF contribution for local employees
EPF_FOREIGN,EPF Foreign,percentage,11,12,foreigner,2025-01-01,,true,EPF for foreign employees
SOCSO,SOCSO,wage_range,0,0,all,2025-01-01,,true,SOCSO contribution for all employees
```

**Columns:**

- `code` (required): Unique deduction code
- `name` (required): Display name
- `calculation_type` (required): `percentage`, `fixed`, or `wage_range`
- `employee_contribution`: Rate/amount (0 for wage_range types)
- `employer_contribution`: Rate/amount (0 for wage_range types)
- `nationality`: `all`, `local`, `foreigner`, `foreigner_no_passport`
- `effective_from`: Start date (default: today)
- `effective_until`: End date (NULL for active deductions)
- `is_active`: `true` or `false` (default: true)
- `description`: Detailed description

### \*\_wage_ranges.csv

```csv
code,min_wage,max_wage,employee_amount,employer_amount,calculation_method
EPF_LOCAL,0.00,100.00,0.00,5.00,fixed
EPF_LOCAL,5000.01,,550.00,600.00,fixed
```

**Columns:**

- `code` (required): Must match deduction type code
- `min_wage` (required): Minimum salary for this range
- `max_wage`: Maximum salary (NULL for open-ended range)
- `employee_amount` (required): Fixed employee deduction
- `employer_amount` (required): Fixed employer contribution
- `calculation_method`: Always `fixed`

**Important:** Ranges must cover all possible salaries without gaps.

## Rake Tasks

### 1. Import Deduction Types

```bash
# Import from default location
rake deductions:import_deduction_types

# Import from custom file
rake deductions:import_deduction_types[path/to/custom.csv]
```

**Behavior:**

- **New records**: Creates new deduction type
- **Existing records**: Updates **metadata only** (name, description, is_active, effective_until)
- **Safety**: Skips if `calculation_type` would change (too risky)
- **No rate changes**: Use `deductions:update_rate` task for versioning rate changes

**Output Example:**

```
=== Importing Deduction Types ===
✓ Created EPF_LOCAL - EPF Local
↻ Updated EPF_FOREIGN - EPF Foreign (active: true)
⊘ Skipped SOCSO_MALAYSIAN - calculation_type change detected
✗ Failed OLD_TAX: Validation error

=== Import Summary ===
✓ Created: 1
↻ Updated: 1
⊘ Skipped: 1
✗ Failed: 0
```

### 2. Import Wage Ranges (Single File)

```bash
# Skip existing ranges (default)
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv]

# Force replace all ranges for this deduction type
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv,true]
```

**Modes:**

- **Skip mode** (default): Only creates missing ranges, preserves existing
- **Force mode** (`force=true`): Deletes ALL ranges for that deduction type, then reimports

**Use Force Mode When:**

- Government updates the entire wage range table
- You need to fix systematic errors in ranges
- You're sure you want to replace all existing data

**Output Example:**

```
=== Importing Wage Ranges ===
Mode: FORCE REPLACE

🗑  Deleted 100 existing ranges for EPF_LOCAL

..........

=== Import Summary ===
🗑  Deleted: 100
✓ Created: 100
⊘ Skipped: 0
✗ Failed: 0
```

### 3. Import All Wage Ranges

```bash
# Skip existing ranges (default)
rake deductions:import_all_wage_ranges

# Wipe and reimport everything
rake deductions:import_all_wage_ranges[true]
```

**Processes:**

- `epf_local_wage_ranges.csv`
- `socso_wage_ranges.csv`
- `eis_local_wage_ranges.csv`

**Modes:**

- **Skip mode** (default): Preserves existing ranges
- **Replace mode** (`replace=true`): Deletes ALL wage ranges from database, then reimports

**⚠️ Warning:** Replace mode deletes ALL wage ranges globally. Use with caution!

**Output Example:**

```
=== Importing All Wage Ranges ===
Mode: REPLACE ALL

🗑  Deleting all existing wage ranges...
🗑  Deleted 225 wage ranges

--- Processing epf_local_wage_ranges.csv ---
..........
  ✓ Created: 100 | ⊘ Skipped: 0 | ✗ Failed: 0

=== Overall Summary ===
🗑  Total Deleted: 225
✓ Total Created: 225
⊘ Total Skipped: 0
✗ Total Failed: 0
```

## Common Workflows

### Initial Setup (New System)

```bash
# 1. Import deduction types first
rake deductions:import_deduction_types

# 2. Import all wage ranges
rake deductions:import_all_wage_ranges
```

### Update Deduction Metadata

Edit `deduction_types.csv` (name, description, is_active), then:

```bash
rake deductions:import_deduction_types
```

### Update Wage Range Table (Government Changes)

When KWSP/SOCSO/PERKESO updates rates:

1. Edit the specific CSV file (e.g., `epf_local_wage_ranges.csv`)
2. Run with force mode:

```bash
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv,true]
```

### Deprecate a Deduction

Edit `deduction_types.csv`:

```csv
OLD_TAX,Old Tax,percentage,5,0,all,2020-01-01,2024-12-31,false,Deprecated tax
```

Then import:

```bash
rake deductions:import_deduction_types
```

### Complete Refresh (Nuclear Option)

```bash
# Wipe everything and reimport
rake deductions:import_deduction_types
rake deductions:import_all_wage_ranges[true]
```

## Implementation Details

### Why Three Calculation Types?

**Percentage Type (`percentage`):**

- Used for: EPF Foreign, SIP
- Simple percentage of gross salary
- Contribution rates stored in deduction_type table
- No wage range tables needed

**Fixed Type (`fixed`):**

- Uses fixed amounts directly from deduction_type table
- Same amount regardless of salary
- Rarely used for statutory deductions

**Wage Range Type (`wage_range`):**

- Used for: EPF Local, SOCSO, EIS
- Uses wage range lookup tables
- More accurate for progressive contribution schemes
- Follows official government tables

### Version Control

Deduction types use **temporal versioning**:

```
EPF_LOCAL v1: 2020-01-01 to 2024-12-31 (old rates)
EPF_LOCAL v2: 2025-01-01 to NULL       (current rates)
```

**Important:** Import task only updates current version (where `effective_until IS NULL`). For rate changes creating new versions, use `deductions:update_rate` task.

### Data Integrity

**Validations:**

- Deduction codes must be unique
- Calculation type must be `percentage`, `fixed`, or `wage_range`
- Wage ranges must not overlap
- Ranges must not have gaps
- All numeric fields validated for proper ranges

**Foreign Key Cascade:**

- Deleting a deduction type deletes all its wage ranges
- Import tasks check deduction type exists before creating ranges

## Troubleshooting

### Error: "calculation_type change detected"

**Cause:** You're trying to change `percentage` to `fixed` or vice versa.

**Solution:** This is intentionally blocked for safety. Create a new deduction type instead.

### Error: "Deduction type not found"

**Cause:** Wage range CSV references a deduction type that doesn't exist.

**Solution:** Import deduction types first:

```bash
rake deductions:import_deduction_types
```

### Ranges Not Applying Correctly

**Check:**

1. Ensure ranges have no gaps or overlaps
2. Verify the last range has `max_wage` = NULL (open-ended)
3. Check deduction type `calculation_type` is `wage_range`
4. Verify `is_active = true` on deduction type

### Import Skipping Everything

**Cause:** Records already exist (default skip behavior).

**Solution:** Use force/replace mode if you want to update:

```bash
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/file.csv,true]
```

## Best Practices

### 1. Version Control Your CSVs

Keep CSV files in Git to track government rate changes over time:

```bash
git add db/master_data/master_data_deductions/*.csv
git commit -m "Update EPF rates effective 2025-01-01"
```

### 2. Test in Staging First

Always test imports in staging before production:

```bash
RAILS_ENV=staging rake deductions:import_all_wage_ranges[true]
```

### 3. Backup Before Replace Mode

Before using replace mode in production:

```bash
# Backup
pg_dump -t deduction_wage_ranges > backup.sql

# Import
rake deductions:import_all_wage_ranges[true]

# Restore if needed
psql < backup.sql
```

### 4. Document Rate Changes

Add comments in CSV files or commit messages:

```csv
# Updated 2025-01-01 per KWSP Circular No. 2025/01
EPF_LOCAL,EPF Local,wage_range,0,0,local,2025-01-01,,true,EPF rates updated
```

### 5. Validate After Import

Check counts and spot-check amounts:

```bash
rails console
> DeductionType.count
> DeductionWageRange.where(deduction_type: DeductionType.find_by(code: 'EPF_LOCAL')).count
> DeductionWageRange.find_for_salary(DeductionType.find_by(code: 'EPF_LOCAL'), 3000)
```

## Related Tasks

- `deductions:update_rate` - Create new version of deduction with new rates
- `deductions:create` - Create single deduction type manually
- `deductions:history` - View rate history for a deduction
- `deductions:active_for_month` - Show active deductions for a specific month

## FAQs

**Q: Why are contributions 0 for wage_range types?**
A: Because actual amounts come from wage range tables, not the deduction_type record.

**Q: Can I mix percentage and wage_range in one deduction?**
A: No. Each deduction type uses one calculation method consistently.

**Q: What happens to old wage ranges when rates change?**
A: Use `update_rate` task to version the deduction type. Old ranges stay for historical payroll calculations.

**Q: Can I import during business hours?**
A: Import is safe (no locks) but use replace mode cautiously. Prefer maintenance windows for large changes.

**Q: How do I add a new deduction type?**
A: Add row to `deduction_types.csv`, create wage range CSV if fixed type, then run import tasks.

## Support

For issues or questions:

1. Check this documentation
2. Review rake task output for error messages
3. Check Rails logs: `log/development.log`
4. Verify CSV format matches examples
5. Contact development team

## Change Log

- **2025-01-01**: Initial implementation with wage range support
- **2025-01-01**: Added force/replace modes for safer updates
- **2025-01-01**: Added effective_until and is_active support
