# Pay Calculation Troubleshooting Guide

## Common Issue: Completed Work Orders Not Creating Pay Calculations

### Symptoms

- Work orders show status `completed`
- No PayCalculation records exist for the workers
- Pay calculation details are missing for specific months

### Root Cause

Pay calculations are triggered by the AASM `approve` event callback in the WorkOrder model. If work orders are:

1. Created directly with `completed` status (bypassing AASM transitions)
2. Missing `completion_date` when approved
3. Have `resources` type (resources-only work orders don't create pay calculations)
4. Have no workers assigned

Then pay calculations will not be created automatically.

---

## Diagnostic Script

Run this in Rails console to diagnose the issue:

```bash
docker compose exec web rails console
```

```ruby
# === DIAGNOSTIC ONLY (no changes) ===
affected_work_order_ids = [87, 88, 89, 90, 91, 92, 94, 97]  # <-- Update with your IDs

puts "🔍 DIAGNOSTIC REPORT"
puts "=" * 70

affected_work_order_ids.each do |wo_id|
  wo = WorkOrder.find_by(id: wo_id)

  if wo.nil?
    puts "❌ WorkOrder ##{wo_id}: NOT FOUND"
    next
  end

  month_year = wo.completion_date&.strftime('%Y-%m')
  pay_calc = PayCalculation.find_by(month_year: month_year) if month_year

  puts "\n📋 WorkOrder ##{wo_id}:"
  puts "   ├─ Status: #{wo.work_order_status}"
  puts "   ├─ Completion Date: #{wo.completion_date || 'MISSING ⚠️'}"
  puts "   ├─ Month/Year: #{month_year || 'N/A'}"
  puts "   ├─ Rate Type: #{wo.work_order_rate&.work_order_rate_type || 'N/A'}"
  puts "   ├─ Rate Name: #{wo.work_order_rate&.work_order_name || 'N/A'}"
  puts "   ├─ Workers: #{wo.work_order_workers.count}"

  if wo.work_order_workers.any?
    wo.work_order_workers.each do |wow|
      puts "   │   └─ #{wow.worker_name}: Rate=#{wow.rate}, Amount=#{wow.amount}"
    end
  end

  puts "   ├─ PayCalculation exists for #{month_year}?: #{pay_calc ? "YES (##{pay_calc.id})" : 'NO'}"

  if pay_calc
    worker_ids = wo.work_order_workers.pluck(:worker_id)
    details = pay_calc.pay_calculation_details.where(worker_id: worker_ids)
    puts "   └─ Workers included in PayCalc: #{details.count}/#{worker_ids.count}"
  end

  # Determine why it might have been skipped
  issues = []
  issues << "Resource-only type" if wo.work_order_rate&.resources?
  issues << "No workers" if wo.work_order_workers.empty?
  issues << "No completion date" if wo.completion_date.nil?
  issues << "Not completed status" unless wo.work_order_status == 'completed'

  if issues.any?
    puts "   ⚠️  ISSUES: #{issues.join(', ')}"
  else
    puts "   ✅ Ready for pay calculation processing"
  end
end
```

---

## Fix Scripts

### Fix Option 1: Set Specific Dates for Each Work Order

Use this when each work order has a different completion date:

```ruby
# === FIX: Set completion dates and process pay calculations ===

# Define the completion dates for each work order
# MODIFY THESE DATES according to actual completion dates!
completion_dates = {
  87 => Date.new(2025, 12, 15),  # Example: December 15, 2025
  88 => Date.new(2025, 12, 16),
  89 => Date.new(2025, 12, 17),
  90 => Date.new(2025, 12, 18),
  91 => Date.new(2025, 12, 19),
  92 => Date.new(2025, 12, 20),
  94 => Date.new(2025, 12, 22),
  97 => Date.new(2025, 12, 25),
}

puts "🔧 Setting completion dates and processing pay calculations..."
puts "=" * 60

ActiveRecord::Base.transaction do
  completion_dates.each do |wo_id, date|
    wo = WorkOrder.find(wo_id)

    puts "\n📋 WorkOrder ##{wo_id}:"
    puts "   Setting completion_date to: #{date}"

    wo.update!(completion_date: date)

    result = PayCalculationServices::ProcessWorkOrderService.new(wo).call

    if result.success?
      puts "   ✅ #{result.value!}"
    else
      puts "   ❌ #{result.failure}"
      raise "Failed to process WorkOrder ##{wo_id}"
    end
  end
end

puts "\n" + "=" * 60
puts "✅ All work orders updated and pay calculations processed!"
```

---

### Fix Option 2: Set All to Same Month

Use this when all work orders belong to the same pay period:

```ruby
# === FIX: Set all to same month and process ===

affected_ids = [87, 88, 89, 90, 91, 92, 94, 97]
completion_date = Date.new(2025, 12, 31)  # <-- CHANGE THIS to correct date

puts "🔧 Setting completion_date to #{completion_date} for all work orders..."
puts "=" * 60

ActiveRecord::Base.transaction do
  affected_ids.each do |wo_id|
    wo = WorkOrder.find(wo_id)

    puts "\n📋 WorkOrder ##{wo_id}:"
    wo.update!(completion_date: completion_date)
    puts "   ├─ completion_date set to: #{completion_date}"

    result = PayCalculationServices::ProcessWorkOrderService.new(wo).call

    if result.success?
      puts "   └─ ✅ #{result.value!}"
    else
      puts "   └─ ❌ #{result.failure}"
      raise "Failed to process WorkOrder ##{wo_id}"
    end
  end
end

puts "\n" + "=" * 60
puts "✅ Done! Check PayCalculation for #{completion_date.strftime('%Y-%m')}"
```

---

### Fix Option 3: Use start_date as Fallback

Use this when `start_date` exists and represents the work period:

```ruby
# === FIX: Use start_date as completion_date ===

affected_ids = [87, 88, 89, 90, 91, 92, 94, 97]

puts "🔧 Using start_date as completion_date..."
puts "=" * 60

ActiveRecord::Base.transaction do
  affected_ids.each do |wo_id|
    wo = WorkOrder.find(wo_id)

    puts "\n📋 WorkOrder ##{wo_id}:"

    if wo.start_date.nil?
      puts "   ⚠️  No start_date either! Skipping..."
      next
    end

    wo.update!(completion_date: wo.start_date)
    puts "   ├─ completion_date set to: #{wo.start_date}"

    result = PayCalculationServices::ProcessWorkOrderService.new(wo).call

    if result.success?
      puts "   └─ ✅ #{result.value!}"
    else
      puts "   └─ ❌ #{result.failure}"
      raise "Failed to process WorkOrder ##{wo_id}"
    end
  end
end

puts "\n" + "=" * 60
puts "✅ Done!"
```

---

## Verification After Fix

After running any of the fix scripts, verify the pay calculations were created:

```ruby
# === VERIFICATION SCRIPT ===

affected_ids = [87, 88, 89, 90, 91, 92, 94, 97]

puts "🔍 VERIFICATION REPORT"
puts "=" * 60

affected_ids.each do |wo_id|
  wo = WorkOrder.find(wo_id)
  month_year = wo.completion_date&.strftime('%Y-%m')
  pay_calc = PayCalculation.find_by(month_year: month_year)

  puts "\n📋 WorkOrder ##{wo_id}:"
  puts "   ├─ Completion Date: #{wo.completion_date}"
  puts "   ├─ Month/Year: #{month_year}"

  if pay_calc
    worker_ids = wo.work_order_workers.pluck(:worker_id)
    details = pay_calc.pay_calculation_details.where(worker_id: worker_ids)

    puts "   ├─ PayCalculation: ##{pay_calc.id}"
    puts "   └─ Workers in PayCalc: #{details.count}/#{worker_ids.count} ✅"

    details.each do |detail|
      puts "       └─ #{detail.worker.name}: RM #{detail.gross_salary}"
    end
  else
    puts "   └─ PayCalculation: MISSING ❌"
  end
end

puts "\n" + "=" * 60
```

---

## Prevention

A validation has been added to prevent this issue in the future:

```ruby
# In app/models/work_order.rb
validates :completion_date,
          presence: { message: 'is required for completed work orders' },
          if: :completed?
```

This ensures that work orders cannot be saved with `completed` status without a `completion_date`.

---

## Understanding Pay Calculation Flow

### When Pay Calculations Are Created

Pay calculations are created automatically when:

1. **Work order transitions to `completed` via AASM `approve` event**

   ```ruby
   work_order.approve!(remarks: 'Approved')
   # This triggers: process_pay_calculation callback
   ```

2. **The work order has:**
   - `completion_date` set (required for determining month/year)
   - At least one worker assigned
   - Non-resources rate type (resources-only orders are skipped)

### Pay Calculation Process

```
WorkOrder.approve!
  └─> process_pay_calculation (after callback)
      └─> PayCalculationServices::ProcessWorkOrderService.new(work_order).call
          ├─> Find or create PayCalculation for completion_date month
          ├─> For each work_order_worker:
          │   ├─> Find or create PayCalculationDetail for worker
          │   ├─> Add work_order_worker.amount to gross_salary
          │   └─> Calculate deductions (based on nationality)
          └─> Recalculate PayCalculation totals
```

### What Gets Skipped

The `ProcessWorkOrderService` will skip processing if:

```ruby
# Skip if resources-only work order
return Success('Resource-only work order') if work_order.work_order_rate&.resources?

# Skip if no workers
return Success('No workers to process') if work_order.work_order_workers.empty?

# Will fail if completion_date is nil
month_year = work_order.completion_date.strftime('%Y-%m')  # Error if nil
```

---

## Related Documentation

- [PAY_CALCULATION_GUIDE.md](./PAY_CALCULATION_GUIDE.md) - Complete pay calculation system guide
- [PAY_CALCULATION_WORK_ORDER_DELETION.md](./PAY_CALCULATION_WORK_ORDER_DELETION.md) - Handling work order deletions
- [DEDUCTION_IMPORT_GUIDE.md](./DEDUCTION_IMPORT_GUIDE.md) - Deduction setup and import

---

## Quick Reference

### Check if Pay Calculation Exists for a Month

```ruby
pay_calc = PayCalculation.find_by(month_year: '2025-12')
```

### Manually Process a Completed Work Order

```ruby
wo = WorkOrder.find(87)
result = PayCalculationServices::ProcessWorkOrderService.new(wo).call

if result.success?
  puts result.value!  # Success message
else
  puts result.failure  # Error message
end
```

### Find All Completed Work Orders Without Pay Calculations

```ruby
completed_wos = WorkOrder.where(work_order_status: 'completed')
                         .where.not(completion_date: nil)

completed_wos.each do |wo|
  month_year = wo.completion_date.strftime('%Y-%m')
  pay_calc = PayCalculation.find_by(month_year: month_year)

  if pay_calc
    # Check if workers from this WO are in the pay calc
    worker_ids = wo.work_order_workers.pluck(:worker_id)
    details_count = pay_calc.pay_calculation_details.where(worker_id: worker_ids).count

    if details_count < worker_ids.count
      puts "⚠️  WO ##{wo.id}: Only #{details_count}/#{worker_ids.count} workers in PayCalc"
    end
  else
    puts "❌ WO ##{wo.id}: No PayCalculation for #{month_year}"
  end
end
```

---

## Common Issue: Wrong Deduction Rate Applied (EPF, SOCSO, etc.)

### Symptoms

- PayCalculationDetails show incorrect deduction amounts
- Deduction rate was updated but existing records use the old rate
- Example: EPF_FOREIGN was set to 11% but should be 2%

### Root Cause

When a DeductionType rate is updated, existing PayCalculationDetails are **not automatically recalculated**. The deductions were calculated at the time the pay calculation was processed, using the rates that were active at that time.

### Fix Script: Update Deduction Rate and Recalculate

Run this in Rails console:

```bash
docker compose exec web rails console
```

```ruby
# === FIX: Update Deduction Rate and Recalculate ===
# Example: EPF_FOREIGN from 11% to 2%

DEDUCTION_CODE = 'EPF_FOREIGN'           # <-- Change this
NEW_EMPLOYEE_RATE = 2.0                  # <-- New employee rate (%)
NEW_EMPLOYER_RATE = 3.0                  # <-- New employer rate (%)
NATIONALITY_FILTER = 'foreigner'         # <-- 'foreigner', 'local', or nil for all

puts "🔍 DIAGNOSTIC: Current #{DEDUCTION_CODE} Deduction Type"
puts "=" * 60

deduction_type = DeductionType.find_by(code: DEDUCTION_CODE)

if deduction_type.nil?
  puts "❌ #{DEDUCTION_CODE} not found!"
  exit
end

puts "Current settings:"
puts "  ├─ ID: #{deduction_type.id}"
puts "  ├─ Name: #{deduction_type.name}"
puts "  ├─ Employee Contribution: #{deduction_type.employee_contribution}%"
puts "  ├─ Employer Contribution: #{deduction_type.employer_contribution}%"
puts "  ├─ Applies to: #{deduction_type.applies_to_nationality}"
puts "  └─ Effective from: #{deduction_type.effective_from}"

# Find all affected pay calculation details
affected_details = if NATIONALITY_FILTER
                     PayCalculationDetail.joins(:worker)
                                         .where(workers: { nationality: NATIONALITY_FILTER })
                   else
                     PayCalculationDetail.all
                   end

puts "\n📊 Affected PayCalculationDetails: #{affected_details.count}"

# Preview what will change (first 5 records)
puts "\n🔍 PREVIEW (first 5 records):"
affected_details.limit(5).each do |detail|
  old_rate = deduction_type.employee_contribution / 100.0
  new_rate = NEW_EMPLOYEE_RATE / 100.0

  old_amount = detail.gross_salary * old_rate
  new_amount = detail.gross_salary * new_rate
  difference = old_amount - new_amount

  puts "  #{detail.worker.name}:"
  puts "    Gross: RM #{detail.gross_salary}"
  puts "    Old (#{deduction_type.employee_contribution}%): RM #{old_amount.round(2)}"
  puts "    New (#{NEW_EMPLOYEE_RATE}%): RM #{new_amount.round(2)}"
  puts "    Savings: RM #{difference.round(2)}"
end

puts "\n" + "=" * 60
puts "⚠️  This will update #{affected_details.count} records."
puts "Type 'yes' to proceed:"
confirmation = gets.chomp

if confirmation != 'yes'
  puts "❌ Aborted."
  exit
end

puts "\n🔧 APPLYING FIX..."
puts "=" * 60

ActiveRecord::Base.transaction do
  # Step 1: Update the DeductionType rate
  puts "\n📝 Step 1: Updating #{DEDUCTION_CODE} rate..."

  old_employee_rate = deduction_type.employee_contribution
  old_employer_rate = deduction_type.employer_contribution

  deduction_type.update!(
    employee_contribution: NEW_EMPLOYEE_RATE,
    employer_contribution: NEW_EMPLOYER_RATE
  )

  puts "  ├─ Employee: #{old_employee_rate}% → #{deduction_type.employee_contribution}%"
  puts "  └─ Employer: #{old_employer_rate}% → #{deduction_type.employer_contribution}%"

  # Step 2: Recalculate all affected PayCalculationDetails
  puts "\n📝 Step 2: Recalculating PayCalculationDetails..."

  success_count = 0
  error_count = 0

  affected_details.find_each do |detail|
    begin
      old_total_deduction = detail.total_deduction
      old_net_salary = detail.net_salary

      # Recalculate deductions using the updated rates
      detail.recalculate_deductions!
      detail.reload

      new_total_deduction = detail.total_deduction
      new_net_salary = detail.net_salary

      if old_total_deduction != new_total_deduction
        print "."
      end

      success_count += 1
    rescue => e
      puts "\n  ❌ #{detail.worker.name}: #{e.message}"
      error_count += 1
    end
  end
  puts ""

  # Step 3: Recalculate PayCalculation totals
  puts "\n📝 Step 3: Recalculating PayCalculation overall totals..."

  affected_pay_calc_ids = affected_details.pluck(:pay_calculation_id).uniq

  affected_pay_calc_ids.each do |pc_id|
    pay_calc = PayCalculation.find(pc_id)
    pay_calc.recalculate_overall_total!
    puts "  ✅ PayCalculation ##{pc_id} (#{pay_calc.month_year})"
  end

  puts "\n" + "=" * 60
  puts "📊 SUMMARY"
  puts "=" * 60
  puts "✅ DeductionType updated: #{DEDUCTION_CODE}"
  puts "   Employee: #{old_employee_rate}% → #{NEW_EMPLOYEE_RATE}%"
  puts "   Employer: #{old_employer_rate}% → #{NEW_EMPLOYER_RATE}%"
  puts "✅ PayCalculationDetails recalculated: #{success_count}"
  puts "❌ Errors: #{error_count}"
  puts "✅ PayCalculations updated: #{affected_pay_calc_ids.count}"
end

puts "\n✅ Fix completed successfully!"
```

### Verification After Fix

```ruby
# === VERIFY DEDUCTION RATE FIX ===

DEDUCTION_CODE = 'EPF_FOREIGN'
NATIONALITY_FILTER = 'foreigner'

deduction_type = DeductionType.find_by(code: DEDUCTION_CODE)
puts "#{DEDUCTION_CODE} Employee Rate: #{deduction_type.employee_contribution}%"
puts "#{DEDUCTION_CODE} Employer Rate: #{deduction_type.employer_contribution}%"

# Check a sample worker
sample = PayCalculationDetail.joins(:worker)
                              .where(workers: { nationality: NATIONALITY_FILTER })
                              .last

if sample
  puts "\nSample #{NATIONALITY_FILTER} worker: #{sample.worker.name}"
  puts "  Gross Salary: RM #{sample.gross_salary}"
  puts "  Total Deduction: RM #{sample.total_deduction}"
  puts "  Net Salary: RM #{sample.net_salary}"

  expected_deduction = sample.gross_salary * (deduction_type.employee_contribution / 100.0)
  puts "  Expected #{DEDUCTION_CODE} (#{deduction_type.employee_contribution}%): RM #{expected_deduction.round(2)}"
end
```

### Common Deduction Rate Fixes

| Deduction Code | Nationality | Correct Employee Rate | Correct Employer Rate |
| -------------- | ----------- | --------------------- | --------------------- |
| EPF_LOCAL      | local       | 11%                   | 12%                   |
| EPF_FOREIGN    | foreigner   | 2%                    | 3%                    |
| SOCSO_LOCAL    | local       | varies by wage        | varies by wage        |

---

## Support

If you continue to experience issues with pay calculations not being created:

1. Run the diagnostic script to identify the root cause
2. Check the application logs for errors
3. Verify the work order was approved via AASM (not directly set to completed)
4. Ensure all prerequisites are met (completion_date, workers, proper rate type)
5. For deduction issues, verify the DeductionType rates are correct for each nationality
