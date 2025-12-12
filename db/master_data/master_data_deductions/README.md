# Deduction CSV Files

This directory contains CSV files for managing statutory deductions (EPF, SOCSO, EIS, SIP) for payroll calculations.

## Files

- **deduction_types.csv** - Master list of all deduction types
- **epf_local_wage_ranges.csv** - EPF Local wage range table (100 ranges, RM 0 - RM 5000+)
- **socso_local_wage_ranges.csv** - SOCSO Malaysian wage range table (45 ranges, RM 0 - RM 4000+)
- **socso_foreign_wage_ranges.csv** - SOCSO Foreign wage range table (45 ranges, RM 0 - RM 4000+)
- **eis_local_wage_ranges.csv** - EIS Local wage range table (4 ranges, RM 0 - RM 4000+)

## Import Commands

```bash
# Import everything (initial setup)
rake deductions:import_deduction_types
rake deductions:import_all_wage_ranges

# Update specific wage table
rake deductions:import_wage_ranges[db/csv/epf_local_wage_ranges.csv,true]

# Complete refresh
rake deductions:import_all_wage_ranges[true]
```

## Editing Guidelines

### When Editing deduction_types.csv

**Safe to change:**

- name (display name)
- description
- is_active (true/false)
- effective_until (to deprecate)

**DO NOT change:**

- code (used as identifier everywhere)
- calculation_type (creates data inconsistency)

**After editing:** Run `rake deductions:import_deduction_types`

### When Editing Wage Range CSV Files

**When government publishes new rates:**

1. Download official rate tables from KWSP/PERKESO/SOCSO
2. Update the corresponding CSV file
3. Verify no gaps in ranges (every RM amount should fall in exactly one range)
4. Ensure last range has empty `max_wage` (open-ended)
5. Test in staging first
6. Run with force mode: `rake deductions:import_wage_ranges[db/csv/file.csv,true]`

**Format rules:**

- All amounts in Ringgit (RM)
- Use 2 decimal places (e.g., 12.25 not 12.3)
- Open-ended range: leave max_wage empty
- No overlapping ranges
- No gaps between ranges

## Version Control

These CSV files are tracked in Git. When making changes:

```bash
git add db/csv/epf_local_wage_ranges.csv
git commit -m "Update EPF Local rates per KWSP Circular 2025/01 effective 2025-01-01"
```

## Validation

After import, verify:

```bash
rails console

# Check specific salary lookup
dt = DeductionType.find_by(code: 'EPF_LOCAL')
DeductionWageRange.find_for_salary(dt, 3000)
# Should return correct employee_amount and employer_amount

# Check range count
DeductionWageRange.where(deduction_type: dt).count
# Should match row count in CSV (minus header)
```

## Official Sources

- **EPF**: https://www.kwsp.gov.my/
- **SOCSO**: https://www.perkeso.gov.my/
- **EIS**: https://www.perkeso.gov.my/en/employment-insurance-system
- **SIP**: Human Resources Development Fund (HRDF)

## Documentation

See full documentation:

- **docs/DEDUCTION_IMPORT_GUIDE.md** - Complete guide with examples
- **docs/DEDUCTION_IMPORT_QUICK_REF.md** - Quick reference and commands

## Support

For questions or issues:

1. Check import task output for error messages
2. Review documentation
3. Check Rails logs: `log/development.log`
4. Contact development team
