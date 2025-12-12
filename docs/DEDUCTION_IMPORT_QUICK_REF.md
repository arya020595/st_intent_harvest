# Deduction Import Quick Reference

## Quick Commands

```bash
# Import deduction types
rake deductions:import_deduction_types

# Import single wage range file (skip existing)
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv]

# Import single wage range file (force replace)
rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv,true]

# Import all wage ranges (skip existing)
rake deductions:import_all_wage_ranges

# Import all wage ranges (wipe and replace)
rake deductions:import_all_wage_ranges[true]
```

## File Locations

```
db/master_data/master_data_deductions/
  deduction_types.csv           # Master deduction list
  epf_local_wage_ranges.csv     # EPF Local (100 ranges)
  socso_wage_ranges.csv         # SOCSO for all workers (65 ranges)
  eis_local_wage_ranges.csv     # EIS Local (60 ranges)
```

## Current Deduction Types

| Code        | Name        | Type       | Employee   | Employer   | Nationality |
| ----------- | ----------- | ---------- | ---------- | ---------- | ----------- |
| EPF_LOCAL   | EPF Local   | wage_range | wage range | wage range | local       |
| EPF_FOREIGN | EPF Foreign | percentage | 11%        | 12%        | foreigner   |
| SOCSO       | SOCSO       | wage_range | wage range | wage range | all         |
| EIS_LOCAL   | EIS Local   | wage_range | wage range | wage range | local       |
| SIP         | SIP         | percentage | 0.2%       | 0.2%       | all         |

## Decision Matrix

### When to use which mode?

| Scenario                           | Command                                             |
| ---------------------------------- | --------------------------------------------------- |
| First time setup                   | `import_deduction_types` + `import_all_wage_ranges` |
| Update deduction name/description  | `import_deduction_types`                            |
| Government updates ONE wage table  | `import_wage_ranges[file,true]`                     |
| Government updates ALL wage tables | `import_all_wage_ranges[true]`                      |
| Add new deduction type             | Add to CSV + `import_deduction_types`               |
| Deprecate deduction                | Set effective_until + `import_deduction_types`      |

## Safety Checklist

Before using **force/replace mode**:

- [ ] Have database backup
- [ ] Tested in staging environment
- [ ] Verified CSV format is correct
- [ ] Confirmed no gaps in wage ranges
- [ ] Reviewed changes in Git diff
- [ ] Notified team of maintenance window

## Import Behavior

| Task                   | Existing Record            | Action                |
| ---------------------- | -------------------------- | --------------------- |
| import_deduction_types | Found, same calc_type      | Update metadata       |
| import_deduction_types | Found, different calc_type | Skip (too risky)      |
| import_deduction_types | Not found                  | Create new            |
| import_wage_ranges     | Found, skip mode           | Skip                  |
| import_wage_ranges     | Found, force mode          | Delete all + recreate |
| import_all_wage_ranges | Found, skip mode           | Skip                  |
| import_all_wage_ranges | Found, replace mode        | Delete ALL + recreate |

## Output Symbols

- ✓ Created
- ↻ Updated
- ⊘ Skipped
- ✗ Failed
- 🗑 Deleted

## Validation Checks

**Deduction Types:**

- ✓ Code unique
- ✓ Calculation type in [`percentage`, `fixed`]
- ✓ Nationality in [`all`, `local`, `foreigner`, `foreigner_no_passport`]
- ✓ Contributions numeric ≥ 0

**Wage Ranges:**

- ✓ min_wage < max_wage
- ✓ Deduction type exists
- ✓ No overlapping ranges
- ✓ All amounts ≥ 0

## Testing After Import

```bash
rails console

# Check counts
DeductionType.count
DeductionWageRange.count

# Test lookup
dt = DeductionType.find_by(code: 'EPF_LOCAL')
DeductionWageRange.find_for_salary(dt, 3000)
# => #<DeductionWageRange employee_amount: 71.0, employer_amount: 120.0>

# Verify active deductions
DeductionType.where(is_active: true, effective_until: nil)
```

## Common Errors & Fixes

| Error                              | Cause                 | Fix                                       |
| ---------------------------------- | --------------------- | ----------------------------------------- |
| "CSV file not found"               | Wrong path            | Use absolute path or check file exists    |
| "calculation_type change detected" | Trying to change type | Create new deduction instead              |
| "Deduction type not found"         | Missing parent record | Import deduction_types first              |
| "Validation failed: not a number"  | Empty CSV field       | Use 0 for fixed types                     |
| All records skipped                | Already exist         | Use force/replace mode if update intended |

## Related Documentation

- Full Guide: `docs/DEDUCTION_IMPORT_GUIDE.md`
- Database Schema: `db/schema.rb` (search: deduction_types, deduction_wage_ranges)
- Models: `app/models/deduction_type.rb`, `app/models/deduction_wage_range.rb`
- Rake Tasks: `lib/tasks/import_deduction_management.rake`

## Contact

For issues: Check logs at `log/development.log` or contact development team.
