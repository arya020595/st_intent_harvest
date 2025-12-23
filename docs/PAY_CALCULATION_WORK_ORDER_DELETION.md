# Pay Calculation & Work Order Deletion Guide

## ✅ Current Status: FIXED

**As of December 2025**, this issue has been fixed with automatic pay calculation reversal.

When a completed work order is soft-deleted, the system automatically:

1. Recalculates affected workers' pay from remaining active work orders
2. Removes PayCalculationDetail records for workers with no remaining earnings
3. Updates PayCalculation totals
4. Removes empty PayCalculation records

When a soft-deleted work order is restored (undiscarded), the system automatically:

1. Reprocesses the pay calculation for that work order
2. Adds the earnings back to affected workers

### Implementation Details

- **Service**: `PayCalculationServices::ReverseWorkOrderService`
- **Callbacks**:
  - `before_discard :reverse_pay_calculation` - Reverses pay calculations before delete (allows transaction rollback on failure)
  - `after_undiscard :reprocess_pay_calculation` - Reprocesses pay calculations on restore
- **Condition**: `if: :needs_pay_calculation_reversal?` - Only for completed work orders with `completion_date`
- **Transaction Safety**: Uses `before_discard` callback - if reversal fails, exception aborts the discard automatically

---

## Historical Context (Pre-Fix)

> **Note**: The sections below document the manual workaround that was needed before the fix was implemented. They are retained for reference in case manual intervention is ever needed.

### Problem Statement

When a **completed** work order is soft-deleted (discarded), the associated `PayCalculation` and `PayCalculationDetail` records are **NOT automatically updated**. This creates a data integrity issue where:

1. Pay calculations still include earnings from deleted work orders
2. Worker totals may be incorrect
3. Monthly totals in `PayCalculation` are stale

### Why This Happens

The `PayCalculationServices::ProcessWorkOrderService` is triggered **only on work order completion** (via AASM `approve` event). There is no reverse operation when a work order is deleted.

```ruby
# In WorkOrder model (app/models/work_order.rb)
event :approve do
  transitions from: :pending, to: :completed do
    after do |*args|
      # ...
      process_pay_calculation  # Only called on approve
    end
  end
end
```

## Workaround: Manual Recalculation

### Step 1: Identify Affected Records

```ruby
# In Rails console
rails c

# Find the deleted work order
deleted_wo = WorkOrder.with_discarded.discarded.find(WORK_ORDER_ID)

# Check the month affected
affected_month = deleted_wo.completion_date&.strftime('%Y-%m')
# => "2025-01"

# Find the pay calculation for that month
pay_calc = PayCalculation.find_by(month_year: affected_month)
```

### Step 2: Identify Affected Workers

```ruby
# Get workers from the deleted work order
affected_worker_ids = WorkOrderWorker.with_discarded
                                      .where(work_order_id: deleted_wo.id)
                                      .pluck(:worker_id)

# Find their pay calculation details
affected_details = PayCalculationDetail.where(
  pay_calculation: pay_calc,
  worker_id: affected_worker_ids
)

puts "Affected workers: #{affected_worker_ids.count}"
affected_details.each do |detail|
  puts "Worker ##{detail.worker_id}: Gross=#{detail.gross_salary}, Net=#{detail.net_salary}"
end
```

### Step 3: Recalculate Worker Pay

```ruby
# For each affected worker, recalculate from remaining active work orders
affected_worker_ids.each do |worker_id|
  # Get all active (non-deleted) completed work orders for this worker in the month
  active_earnings = WorkOrderWorker
    .joins(:work_order)
    .where(worker_id: worker_id)
    .where(work_orders: {
      work_order_status: 'completed',
      completion_date: pay_calc.month_year_date.beginning_of_month..pay_calc.month_year_date.end_of_month
    })
    .sum(:amount)

  detail = PayCalculationDetail.find_by(pay_calculation: pay_calc, worker_id: worker_id)

  if active_earnings.zero?
    # Worker has no remaining earnings for this month - remove the detail
    puts "Removing PayCalculationDetail for Worker ##{worker_id} (no remaining earnings)"
    detail&.destroy
  else
    # Update with recalculated earnings
    puts "Updating Worker ##{worker_id}: #{detail.gross_salary} -> #{active_earnings}"
    detail.update!(gross_salary: active_earnings)
    detail.recalculate_deductions!
  end
end
```

### Step 4: Recalculate PayCalculation Totals

```ruby
# Recalculate the overall totals
pay_calc.recalculate_overall_total!

puts "Updated PayCalculation ##{pay_calc.id}:"
puts "  Total Gross: #{pay_calc.total_gross_salary}"
puts "  Total Deductions: #{pay_calc.total_deductions}"
puts "  Total Net: #{pay_calc.total_net_salary}"
```

## Complete Script (Copy-Paste Ready)

```ruby
# === WORK ORDER DELETION PAY CALCULATION FIX ===
# Replace WORK_ORDER_ID with the actual ID

WORK_ORDER_ID = 123  # <-- Change this

# Find deleted work order
deleted_wo = WorkOrder.with_discarded.discarded.find(WORK_ORDER_ID)
affected_month = deleted_wo.completion_date&.strftime('%Y-%m')

if affected_month.nil?
  puts "❌ Work order has no completion_date - was it ever completed?"
  return
end

pay_calc = PayCalculation.find_by(month_year: affected_month)

if pay_calc.nil?
  puts "❌ No PayCalculation found for #{affected_month}"
  return
end

puts "📅 Fixing PayCalculation for #{affected_month}"

# Get affected workers
affected_worker_ids = WorkOrderWorker.with_discarded
                                      .where(work_order_id: deleted_wo.id)
                                      .pluck(:worker_id)

puts "👷 Affected workers: #{affected_worker_ids}"

# Helper to get month date range
month_start = Date.parse("#{affected_month}-01")
month_end = month_start.end_of_month

ActiveRecord::Base.transaction do
  affected_worker_ids.each do |worker_id|
    # Recalculate from active work orders only
    active_earnings = WorkOrderWorker
      .joins(:work_order)
      .where(worker_id: worker_id)
      .where(work_orders: {
        work_order_status: 'completed',
        completion_date: month_start..month_end
      })
      .sum(:amount)

    detail = PayCalculationDetail.find_by(pay_calculation: pay_calc, worker_id: worker_id)

    if detail.nil?
      puts "  ⚠️ Worker ##{worker_id}: No PayCalculationDetail found (skipping)"
      next
    end

    if active_earnings.zero?
      puts "  🗑️ Worker ##{worker_id}: Removing (no remaining earnings)"
      detail.destroy!
    else
      old_gross = detail.gross_salary
      detail.update!(gross_salary: active_earnings)
      detail.recalculate_deductions!
      puts "  ✅ Worker ##{worker_id}: #{old_gross} -> #{active_earnings}"
    end
  end

  # Recalculate totals
  pay_calc.recalculate_overall_total!

  puts "\n📊 Updated PayCalculation ##{pay_calc.id}:"
  puts "   Total Gross: #{pay_calc.total_gross_salary}"
  puts "   Total Deductions: #{pay_calc.total_deductions}"
  puts "   Total Net: #{pay_calc.total_net_salary}"
end

puts "\n✅ Done!"
```

## Complete Script for Multiple Work Orders

When you need to fix pay calculations for **multiple** deleted work orders at once:

```ruby
# === FIX PAY CALCULATIONS FOR MULTIPLE DELETED WORK ORDERS ===
# Replace with your work order IDs

DELETED_WORK_ORDER_IDS = [119, 109, 108, 110]  # <-- Change this

# Find all deleted work orders
deleted_work_orders = WorkOrder.with_discarded.discarded.where(id: DELETED_WORK_ORDER_IDS)

puts "Found #{deleted_work_orders.count} deleted work orders"

# Group by month for efficient processing
work_orders_by_month = deleted_work_orders.group_by { |wo| wo.completion_date&.strftime('%Y-%m') }

ActiveRecord::Base.transaction do
  work_orders_by_month.each do |month_year, work_orders|
    next if month_year.nil?

    puts "\n📅 Processing month: #{month_year}"

    pay_calc = PayCalculation.find_by(month_year: month_year)
    unless pay_calc
      puts "  ⚠️ No PayCalculation found for #{month_year} - skipping"
      next
    end

    # Get all affected worker IDs from these work orders
    affected_worker_ids = WorkOrderWorker.with_discarded
                                          .where(work_order_id: work_orders.map(&:id))
                                          .pluck(:worker_id)
                                          .uniq

    puts "  👷 Affected workers: #{affected_worker_ids.count}"

    month_start = Date.parse("#{month_year}-01")
    month_end = month_start.end_of_month

    affected_worker_ids.each do |worker_id|
      # Recalculate from ACTIVE (non-deleted) completed work orders only
      active_earnings = WorkOrderWorker
        .joins(:work_order)
        .where(worker_id: worker_id)
        .merge(WorkOrder.kept) # Only non-discarded
        .where(work_orders: {
          work_order_status: 'completed',
          completion_date: month_start..month_end
        })
        .sum(:amount)

      detail = PayCalculationDetail.find_by(pay_calculation: pay_calc, worker_id: worker_id)

      if detail.nil?
        puts "    ⚠️ Worker ##{worker_id}: No detail found (skipping)"
        next
      end

      if active_earnings.zero?
        puts "    🗑️ Worker ##{worker_id}: Removing (#{detail.gross_salary} -> 0)"
        detail.destroy!
      else
        old_gross = detail.gross_salary
        detail.update!(gross_salary: active_earnings)
        detail.recalculate_deductions!
        puts "    ✅ Worker ##{worker_id}: #{old_gross} -> #{active_earnings}"
      end
    end

    # Recalculate totals
    pay_calc.reload

    if pay_calc.pay_calculation_details.exists?
      pay_calc.recalculate_overall_total!
      puts "\n  📊 Updated PayCalculation ##{pay_calc.id}:"
      puts "     Total Gross: #{pay_calc.total_gross_salary}"
      puts "     Total Net: #{pay_calc.total_net_salary}"
    else
      puts "\n  🗑️ Removing empty PayCalculation ##{pay_calc.id}"
      pay_calc.destroy!
    end
  end
end

puts "\n✅ Done!"
```

---

## ⚠️ CORRECT Way to Delete Completed Work Orders

### DO NOT: Direct Soft-Delete

```ruby
# ❌ WRONG - This leaves orphaned pay calculation data
work_order.discard
# or
work_order.discard!
```

### DO: Use the Proper Deletion Process

#### Method 1: Manual Steps (Current Workaround)

```ruby
# ✅ CORRECT - Step by step process
work_order = WorkOrder.find(WORK_ORDER_ID)

# Step 1: Check if it's completed
unless work_order.completed?
  work_order.discard!
  puts "Work order discarded (was not completed, no pay calc impact)"
  return
end

# Step 2: Get month and workers BEFORE discarding
month_year = work_order.completion_date.strftime('%Y-%m')
affected_worker_ids = work_order.work_order_workers.pluck(:worker_id)

# Step 3: Discard the work order
work_order.discard!
puts "Work order ##{work_order.id} discarded"

# Step 4: Fix pay calculations
pay_calc = PayCalculation.find_by(month_year: month_year)

if pay_calc
  month_start = Date.parse("#{month_year}-01")
  month_end = month_start.end_of_month

  affected_worker_ids.each do |worker_id|
    active_earnings = WorkOrderWorker
      .joins(:work_order)
      .where(worker_id: worker_id)
      .merge(WorkOrder.kept)
      .where(work_orders: {
        work_order_status: 'completed',
        completion_date: month_start..month_end
      })
      .sum(:amount)

    detail = PayCalculationDetail.find_by(pay_calculation: pay_calc, worker_id: worker_id)
    next unless detail

    if active_earnings.zero?
      detail.destroy!
    else
      detail.update!(gross_salary: active_earnings)
      detail.recalculate_deductions!
    end
  end

  pay_calc.reload
  if pay_calc.pay_calculation_details.exists?
    pay_calc.recalculate_overall_total!
  else
    pay_calc.destroy!
  end
end

puts "✅ Work order deleted and pay calculations updated"
```

#### Method 2: Create a Helper Service (Recommended)

Create a service that handles everything:

```ruby
# Usage:
result = WorkOrderServices::SafeDeleteService.new(work_order).call

if result.success?
  puts result.value!
else
  puts "Error: #{result.failure}"
end
```

See "Future Prevention Options" below for the service implementation.

---

## 🛡️ How to PREVENT This Issue

### Option 1: Policy - Don't Delete Completed Work Orders

The safest approach is to **never delete completed work orders**. Instead:

1. **Mark as cancelled** - Add a `cancelled` status instead of deleting
2. **Create adjustment work orders** - Create a negative/correction work order
3. **Admin approval required** - Require manager approval before any deletion

### Option 2: UI Restriction

In your controller/policy, prevent deletion of completed work orders:

```ruby
# app/policies/work_order_policy.rb
class WorkOrderPolicy < ApplicationPolicy
  def destroy?
    return false if record.completed?

    # Only allow deletion of non-completed work orders
    user.has_permission?('work_orders.details.destroy')
  end
end
```

### Option 3: Model Validation

Add a guard in the model:

```ruby
# app/models/work_order.rb
before_discard :prevent_completed_deletion

private

def prevent_completed_deletion
  if completed? && !Current.user&.superadmin?
    errors.add(:base, 'Completed work orders cannot be deleted. Contact administrator.')
    throw(:abort)
  end
end
```

### Option 4: Auto-Reverse on Discard (✅ IMPLEMENTED)

This option has been **implemented** in the codebase. Here's the current implementation:

```ruby
# app/models/work_order.rb

# Discard callbacks - handle pay calculation updates on soft-delete/restore
# Uses before_discard to ensure reversal happens before soft-delete, allowing transaction rollback on failure
before_discard :reverse_pay_calculation, if: :needs_pay_calculation_reversal?
after_undiscard :reprocess_pay_calculation, if: :needs_pay_calculation_reversal?

# Condition for pay calculation callbacks (must be public for callback conditions)
# Returns true if this work order has pay calculations that need to be managed
def needs_pay_calculation_reversal?
  completed? && completion_date.present?
end

private

# Discard callback - reverses pay calculations when work order is soft-deleted
# Raises an exception if reversal fails to abort the discard transaction
def reverse_pay_calculation
  result = PayCalculationServices::ReverseWorkOrderService.new(self).call

  if result.failure?
    error_message = "Pay calculation reversal failed for WorkOrder ##{id}: #{result.failure}"
    AppLogger.error(error_message)
    raise StandardError, error_message
  end

  AppLogger.info("Pay calculation reversed for WorkOrder ##{id}: #{result.value!}")
end

# Undiscard callback - reprocesses pay calculations when work order is restored
# This ensures pay calculations are recalculated after restoring a deleted work order
def reprocess_pay_calculation
  result = PayCalculationServices::ProcessWorkOrderService.new(self).call

  if result.failure?
    error_message = "Pay calculation reprocessing failed for WorkOrder ##{id}: #{result.failure}"
    AppLogger.error(error_message)
    # Don't raise here - restoration should still succeed, pay calc can be fixed manually
  else
    AppLogger.info("Pay calculation reprocessed for WorkOrder ##{id}: #{result.value!}")
  end
end
```

**Key Features:**

- ✅ Conditional callback pattern for clarity
- ✅ `before_discard` reverses pay calculations (exception aborts discard automatically)
- ✅ `after_undiscard` automatically reprocesses pay calculations when restored
- ✅ No custom transaction wrapping needed - Discard gem handles rollback on exception

---

## Implementation Details

### The ReverseWorkOrderService

The service that handles pay calculation reversal:

```ruby
# app/services/pay_calculation_services/reverse_work_order_service.rb
module PayCalculationServices
  class ReverseWorkOrderService
    include Dry::Monads[:result]

    MONTH_YEAR_FORMAT = '%Y-%m'

    attr_reader :work_order

    def initialize(work_order)
      @work_order = work_order
    end

    def call
      return Success('Not completed') unless work_order.completed?
      return Success('No completion date') unless work_order.completion_date.present?
      return Success('Resource-only work order, no pay calculation impact') if resource_only?

      pay_calc = find_pay_calculation
      return Success('No pay calculation found') unless pay_calc

      ActiveRecord::Base.transaction do
        recalculate_affected_workers(pay_calc)
        update_or_destroy_pay_calculation(pay_calc)
      end

      Success("Reversed pay calculation for #{month_year}")
    rescue StandardError => e
      Failure("Failed to reverse: #{e.message}")
    end

    private

    def resource_only?
      work_order.work_order_rate_type == 'resources'
    end

    def month_year
      @month_year ||= work_order.completion_date.strftime(MONTH_YEAR_FORMAT)
    end

    def month_range
      @month_range ||= begin
        month_start = Date.parse("#{month_year}-01")
        month_start..month_start.end_of_month
      end
    end

    def find_pay_calculation
      PayCalculation.find_by(month_year: month_year)
    end

    def affected_worker_ids
      @affected_worker_ids ||= work_order.work_order_workers.pluck(:worker_id)
    end

    def recalculate_affected_workers(pay_calc)
      # Batch load all affected workers' pay calculation details to avoid N+1
      details_by_worker = pay_calc.pay_calculation_details
                                  .where(worker_id: affected_worker_ids)
                                  .index_by(&:worker_id)

      # Calculate active earnings for all affected workers in a single query
      active_earnings_by_worker = calculate_active_earnings_batch

      # Process each affected worker
      affected_worker_ids.each do |worker_id|
        detail = details_by_worker[worker_id]
        next unless detail

        active_earnings = active_earnings_by_worker[worker_id] || 0

        if active_earnings.zero?
          # Worker has no remaining earnings for this month - remove the detail
          AppLogger.info("ReverseWorkOrderService: Removing PayCalculationDetail for Worker ##{worker_id}")
          detail.destroy!
        else
          # Update with recalculated earnings
          old_gross = detail.gross_salary
          detail.update!(gross_salary: active_earnings)
          detail.recalculate_deductions!
          AppLogger.info("ReverseWorkOrderService: Updated Worker ##{worker_id}: #{old_gross} -> #{active_earnings}")
        end
      end
    end

    # Calculate active earnings for all affected workers in a single query
    # Returns a hash of { worker_id => total_amount }
    def calculate_active_earnings_batch
      WorkOrderWorker
        .joins(:work_order)
        .where(worker_id: affected_worker_ids)
        .where.not(work_order_id: work_order.id)
        .merge(WorkOrder.kept) # Only non-discarded work orders
        .where(work_orders: {
                 work_order_status: 'completed',
                 completion_date: month_range
               })
        .group(:worker_id)
        .sum(:amount)
    end

    def update_or_destroy_pay_calculation(pay_calc)
      pay_calc.reload

      if pay_calc.pay_calculation_details.exists?
        # Recalculate totals
        pay_calc.recalculate_overall_total!
        AppLogger.info("ReverseWorkOrderService: Updated PayCalculation ##{pay_calc.id} for #{month_year}")
      else
        # No more details - remove the empty pay calculation
        AppLogger.info("ReverseWorkOrderService: Removing empty PayCalculation ##{pay_calc.id}")
        pay_calc.destroy!
      end
    end
  end
end
```

### Option 2: Use Rake Task for Batch Recalculation

```ruby
# lib/tasks/pay_calculations.rake
namespace :pay_calculations do
  desc "Recalculate pay calculation for a specific month"
  task :recalculate, [:month_year] => :environment do |_t, args|
    month_year = args[:month_year] || Date.current.strftime('%Y-%m')

    puts "Recalculating pay calculations for #{month_year}..."

    PayCalculationServices::MonthlyRecalculationService.new(month_year).call

    puts "Done!"
  end
end
```

### Option 3: Admin UI Action

Add a "Recalculate" button in the Pay Calculations admin view that triggers recalculation from scratch based on active completed work orders.

## Related Files

- `app/models/work_order.rb` - WorkOrder model with AASM
- `app/models/pay_calculation.rb` - PayCalculation model
- `app/models/pay_calculation_detail.rb` - PayCalculationDetail model
- `app/services/pay_calculation_services/process_work_order_service.rb` - Original processing service

## See Also

- [PAY_CALCULATION_GUIDE.md](PAY_CALCULATION_GUIDE.md) - General pay calculation documentation
- [SOFT_DELETE_GUIDE.md](SOFT_DELETE_GUIDE.md) - Soft delete patterns in the application
