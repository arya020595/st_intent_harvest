# Pay Calculation Quick Reference

## Quick Start

### Automatic Trigger

Pay calculations are automatically triggered when a Work Order is approved:

```ruby
work_order.approve!(remarks: "Approved by manager")
# Pay calculation automatically processed for the month
```

### Manual Trigger (if needed)

```ruby
service = PayCalculationServices::ProcessWorkOrderService.new(work_order)
result = service.call

if result.success?
  puts result.value!  # "Pay calculation processed successfully for 2025-01"
else
  puts result.failure  # Error message
end
```

## Key Formulas

### Gross Salary Calculation

**For work_days rate type:**

```ruby
gross_salary = work_days × rate
```

**For normal/resources rate type:**

```ruby
gross_salary = work_area_size × rate
```

### Net Salary Calculation

```ruby
net_salary = gross_salary - worker_deductions
# Automatically calculated on save based on active DeductionTypes
```

### Deductions

```ruby
# Automatically calculated from active DeductionTypes
worker_deductions = SUM(active DeductionType.worker_amount)
employee_deductions = SUM(active DeductionType.employee_amount)
```

### Overall Total

```ruby
overall_total = SUM(all net_salary for the month)
# Automatically recalculated after processing
```

## Common Operations

### Find Pay Calculation for a Month

```ruby
# Find existing
pay_calc = PayCalculation.find_by(month_year: "2025-01")

# Find or create
pay_calc = PayCalculation.find_or_create_for_month("2025-01")
```

### Get Worker's Pay Details for a Month

```ruby
pay_calc = PayCalculation.find_by(month_year: "2025-01")
worker_detail = pay_calc.pay_calculation_details.find_by(worker_id: worker.id)

puts "Gross: #{worker_detail.gross_salary}"
puts "Worker Deductions: #{worker_detail.worker_deductions}"
puts "Employee Deductions: #{worker_detail.employee_deductions}"
puts "Net: #{worker_detail.net_salary}"
puts "Breakdown: #{worker_detail.deduction_breakdown}"
```

### Manage Deduction Types

```ruby
# View active deductions
DeductionType.active

# Update deduction amounts
socso = DeductionType.find_by(code: 'SOCSO')
socso.update!(worker_amount: 25.00, employee_amount: 80.00)

# Enable/disable deductions
epf = DeductionType.find_by(code: 'EPF')
epf.update!(is_active: true)

# After updating deductions, recalculate existing records
PayCalculationDetail.find_each(&:save!)
```

### Get All Workers for a Month

```ruby
pay_calc = PayCalculation.find_by(month_year: "2025-01")
workers = pay_calc.workers  # Through association
# or
details = pay_calc.pay_calculation_details.includes(:worker)
```

## Important Notes

1. **Month Determination**: Based on Work Order's `created_at`, not approval date
2. **Accumulation**: Same worker's gross salary accumulates across multiple work orders in the same month
3. **Auto-calculation**: Deductions and `net_salary` are automatically calculated when saving `PayCalculationDetail` based on active `DeductionTypes`
4. **Transaction**: All calculations happen within a database transaction for data consistency
5. **Logging**: Success/failure is logged via `AppLogger`
6. **Deduction Management**: See `docs/DEDUCTION_MANAGEMENT.md` for managing EPF, SOCSO, SIP deductions

## Data Model

### PayCalculation

```ruby
{
  month_year: "2025-01",        # String (YYYY-MM)
  overall_total: 2500.00        # Decimal
}
```

### PayCalculationDetail

```ruby
{
  pay_calculation_id: 1,
  worker_id: 123,
  gross_salary: 2333.40,        # Decimal
  worker_deductions: 21.25,     # Decimal (auto-calculated from DeductionTypes)
  employee_deductions: 74.35,   # Decimal (auto-calculated from DeductionTypes)
  deductions: 21.25,            # Decimal (legacy field, same as worker_deductions)
  net_salary: 2312.15,          # Decimal (auto-calculated: gross - worker_deductions)
  currency: "RM",               # String
  deduction_breakdown: {        # JSONB
    "SOCSO": {
      "name": "SOCSO",
      "worker": 21.25,
      "employee": 74.35
    }
  }
}
```

## Testing

### Run all pay calculation tests

```bash
rails test test/services/pay_calculation_services/
rails test test/models/pay_calculation_test.rb
rails test test/models/pay_calculation_detail_test.rb
```

### Console Testing

```ruby
# In rails console
work_order = WorkOrder.last
service = PayCalculationServices::ProcessWorkOrderService.new(work_order)
result = service.call

if result.success?
  month = work_order.created_at.strftime('%Y-%m')
  pay_calc = PayCalculation.find_by(month_year: month)

  puts "Month: #{pay_calc.month_year}"
  puts "Overall Total: #{pay_calc.overall_total}"
  puts "\nDetails:"

  pay_calc.pay_calculation_details.each do |detail|
    puts "  #{detail.worker.name}: Gross=#{detail.gross_salary}, Worker Deductions=#{detail.worker_deductions}, Net=#{detail.net_salary}"
    puts "    Breakdown: #{detail.deduction_breakdown}"
  end
end
```

## Troubleshooting

### Pay calculation not triggered

- Check if Work Order has workers
- Verify Work Order status is changing from `pending` to `completed`
- Check logs: `tail -f log/development.log | grep "Pay calculation"`

### Incorrect gross salary

- Verify `work_order_rate_type` is set correctly
- Check `work_area_size`/`work_days` and `rate` values on WorkOrderWorker
- Review calculation logic in service

### Overall total doesn't match

- Call `pay_calculation.recalculate_overall_total!` to refresh
- Check if all net_salary values are correct

### Incorrect deductions

- Verify `DeductionType` records and their `is_active` status
- Check `worker_amount` and `employee_amount` values
- Use `docker compose exec web rails runner "puts DeductionType.active.to_yaml"` to view active deductions
- After updating deduction types, recalculate: `PayCalculationDetail.find_each(&:save!)`

### Worker appearing twice

- This is expected if worker is in multiple work orders in same month
- Gross salary accumulates, not duplicates
