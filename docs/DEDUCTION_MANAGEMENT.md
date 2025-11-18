# Deduction Management System

## Overview

Simple database-backed deduction system for managing EPF, SOCSO, SIP and other payroll deductions.

## Design Decision

**Chose simplicity over complexity**: Store fixed RM amounts directly in `deduction_types` table instead of complex percentage-based calculations with salary brackets.

## Database Structure

### DeductionType Table

Stores deduction types with fixed amounts:

```ruby
{
  name: "SOCSO",
  code: "SOCSO",
  description: "Social Security Organization",
  is_active: true,
  worker_amount: 21.25,      # RM deducted from worker salary
  employee_amount: 74.35     # RM paid by employer
}
```

### PayCalculationDetail Fields

Added to store deduction breakdown:

- `deduction_breakdown` (jsonb): Detailed breakdown per deduction type
- `worker_deductions` (decimal): Total worker deductions
- `employee_deductions` (decimal): Total employer deductions

## How It Works

### 1. Configure Deduction Types

```ruby
# In Rails console or via admin interface
DeductionType.create!(
  name: 'SOCSO',
  code: 'SOCSO',
  worker_amount: 21.25,
  employee_amount: 74.35,
  is_active: true
)
```

### 2. Automatic Calculation

When a `PayCalculationDetail` is saved, it automatically:

1. Loops through all active deduction types
2. Sums up worker and employee amounts
3. Stores breakdown in JSON format
4. Calculates `net_salary = gross_salary - worker_deductions`

### 3. Example Flow

```ruby
# Work order approved → Pay calculation detail created
detail = PayCalculationDetail.new(
  gross_salary: 2333.40,
  currency: 'RM'
)
detail.save!

# Automatically calculated:
# worker_deductions: 21.25 (SOCSO only, since EPF and SIP are disabled)
# employee_deductions: 74.35
# net_salary: 2312.15 (2333.40 - 21.25)
# deduction_breakdown: {
#   "SOCSO" => {
#     "name" => "SOCSO",
#     "worker" => 21.25,
#     "employee" => 74.35
#   }
# }
```

## Managing Deductions

### View All Deductions

```ruby
DeductionType.all
DeductionType.active  # Only active deductions
```

### Update Deduction Amounts

```ruby
socso = DeductionType.find_by(code: 'SOCSO')
socso.update!(
  worker_amount: 25.00,
  employee_amount: 80.00
)
```

### Enable/Disable Deductions

```ruby
epf = DeductionType.find_by(code: 'EPF')
epf.update!(is_active: true)  # Enable
epf.update!(is_active: false) # Disable
```

### Add New Deduction Type

```ruby
DeductionType.create!(
  name: 'Zakat',
  code: 'ZAKAT',
  worker_amount: 50.00,
  employee_amount: 0.00,
  is_active: true
)
```

## Deduction Breakdown Format

The `deduction_breakdown` field stores JSON:

```json
{
  "EPF": {
    "name": "EPF",
    "worker": 0.0,
    "employee": 0.0
  },
  "SOCSO": {
    "name": "SOCSO",
    "worker": 21.25,
    "employee": 74.35
  },
  "SIP": {
    "name": "SIP",
    "worker": 0.0,
    "employee": 0.0
  }
}
```

## Accessing Deduction Data

### In Views

```ruby
# Show deduction breakdown
<% @pay_calculation_detail.deduction_breakdown.each do |code, amounts| %>
  <tr>
    <td><%= amounts['name'] %></td>
    <td>RM <%= amounts['worker'] %></td>
    <td>RM <%= amounts['employee'] %></td>
  </tr>
<% end %>

# Show totals
Worker Deductions: RM <%= @pay_calculation_detail.worker_deductions %>
Employer Deductions: RM <%= @pay_calculation_detail.employee_deductions %>
Net Salary: RM <%= @pay_calculation_detail.net_salary %>
```

### In Controllers

```ruby
# Get deduction summary for a month
pay_calc = PayCalculation.find_by(month_year: '2025-01')
total_worker_deductions = pay_calc.pay_calculation_details.sum(:worker_deductions)
total_employer_deductions = pay_calc.pay_calculation_details.sum(:employee_deductions)
```

## Recalculating Existing Records

If you update deduction amounts, you need to recalculate existing records:

```ruby
# Recalculate all details for a specific month
pay_calc = PayCalculation.find_by(month_year: '2025-01')
pay_calc.pay_calculation_details.find_each do |detail|
  detail.save!  # Triggers recalculation
end
pay_calc.recalculate_overall_total!

# Or recalculate all
PayCalculationDetail.find_each(&:save!)
```

## Future Enhancements

If you need percentage-based or salary-bracket deductions later, you can:

1. Add `calculation_type` field (fixed/percentage)
2. Add `worker_rate_percentage` and `employee_rate_percentage` fields
3. Update the `calculate_deductions` method in PayCalculationDetail

For now, the simple fixed-amount approach is sufficient and easy to manage.

## Seed Data

Default deduction types are created via:

```bash
docker compose exec web rails runner db/seeds/deduction_types.rb
```

Or add to `db/seeds.rb`:

```ruby
load Rails.root.join('db', 'seeds', 'deduction_types.rb')
```

## Summary

✅ **Simple**: Fixed RM amounts, no complex calculations
✅ **Flexible**: Easy to add/remove/update deduction types
✅ **Automatic**: Deductions calculated on save
✅ **Detailed**: JSON breakdown stored for reporting
✅ **Scalable**: Can be enhanced with percentages later if needed
