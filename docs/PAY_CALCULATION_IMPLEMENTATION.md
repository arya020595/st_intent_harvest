# Pay Calculation Implementation

## Overview

This implementation automatically calculates and maintains monthly worker pay summaries when Work Orders are completed (approved).

## Components Created/Modified

### 1. Service: `PayCalculationServices::ProcessWorkOrderService`

**Location:** `app/services/pay_calculation_services/process_work_order_service.rb`

**Purpose:** Handles the pay calculation logic when a work order is completed.

**Key Features:**

- Uses Dry::Monads for consistent result handling
- Determines month based on Work Order's `created_at` date (format: YYYY-MM)
- Finds or creates `PayCalculation` record for the month
- Processes each worker in the work order
- Calculates gross salary based on rate type:
  - **work_days type:** `gross_salary = work_days * rate`
  - **normal/resources type:** `gross_salary = work_area_size * rate`
- Accumulates gross salary for workers across multiple work orders in the same month
- Recalculates overall total after processing

### 2. Model: `WorkOrder`

**Location:** `app/models/work_order.rb`

**Changes:**

- Added callback to `approve` event to trigger pay calculation
- Added `process_pay_calculation` method that calls the service
- Logs success/failure of pay calculation processing

### 3. Model: `PayCalculation`

**Location:** `app/models/pay_calculation.rb`

**Changes:**

- Added `find_or_create_for_month(month_year)` class method for finding/creating by month
- Added `recalculate_overall_total!` method to sum all net salaries from details

### 4. Model: `PayCalculationDetail`

**Location:** `app/models/pay_calculation_detail.rb`

**Changes:**

- Added `deduction_breakdown` (jsonb) field to store detailed deduction breakdown
- Added `worker_deductions` and `employee_deductions` fields for totals
- Added `before_save :calculate_deductions` callback to calculate deductions from active DeductionTypes
- Added `before_save :calculate_net_salary` callback
- Automatically calculates `net_salary = gross_salary - worker_deductions`

### 5. Model: `DeductionType`

**Location:** `app/models/deduction_type.rb`

**Purpose:** Stores configurable deduction types (EPF, SOCSO, SIP) with fixed RM amounts

**Fields:**

- `name` - Display name (e.g., "SOCSO")
- `code` - Unique code (e.g., "SOCSO")
- `worker_amount` - Fixed amount deducted from worker (e.g., 21.25)
- `employee_amount` - Fixed amount paid by employer (e.g., 74.35)
- `is_active` - Whether deduction is currently applied

### 6. Tests

**Location:** `test/services/pay_calculation_services/process_work_order_service_test.rb`

**Test Coverage:**

- Pay calculation creation for work order month
- Pay calculation details creation for each worker
- Gross salary calculation for normal rate type
- Gross salary calculation for work_days rate type
- Net salary calculation (gross - deductions)
- Accumulation of gross salary across multiple work orders
- Overall total recalculation
- Success/failure result handling

## Flow

1. **Trigger:** Work Order status changes from `pending` to `completed` (via `approve` event)

2. **Process:**

   - Extract month from Work Order's `created_at` (format: YYYY-MM)
   - Find or create `PayCalculation` record for that month
   - For each worker in the work order:
     - Calculate gross salary based on rate type
     - Find or create `PayCalculationDetail` for the worker and month
     - Add to existing gross salary (accumulates across work orders)
     - Calculate deductions from active DeductionTypes (automatic via callback)
     - Calculate worker_deductions and employee_deductions totals
   - `PayCalculationDetail` automatically calculates net_salary before save
   - Recalculate `PayCalculation.overall_total` (sum of all net salaries)

3. **Result:**
   - Success: Log confirmation message
   - Failure: Log error message with details

## Usage Example

```ruby
# When a work order is approved
work_order.approve!(remarks: "Approved by manager")

# The callback automatically:
# 1. Calls PayCalculationServices::ProcessWorkOrderService
# 2. Creates/updates PayCalculation for the month
# 3. Creates/updates PayCalculationDetails for each worker
# 4. Calculates gross_salary, net_salary, and overall_total
```

## Key Features

### Accumulation

If the same worker appears in multiple work orders in the same month, their gross salary accumulates:

```ruby
# Work Order 1 in Jan 2025: Worker A earns 1000
# Work Order 2 in Jan 2025: Worker A earns 500
# Result: Worker A's gross_salary for Jan 2025 = 1500
```

### Automatic Net Salary Calculation

Net salary and deductions are automatically calculated whenever a `PayCalculationDetail` is saved:

```ruby
detail.gross_salary = 2333.40
detail.save!
# Automatically calculated based on active DeductionTypes:
# worker_deductions = 21.25 (SOCSO)
# employee_deductions = 74.35 (SOCSO)
# net_salary = 2312.15 (2333.40 - 21.25)
# deduction_breakdown = {"SOCSO" => {"name" => "SOCSO", "worker" => 21.25, "employee" => 74.35}}
```

### Month Determination

The month is determined from the Work Order's `created_at`, not the approval date:

```ruby
# Work Order created on 2025-01-15
# Approved on 2025-02-05
# Pay Calculation month_year: "2025-01"
```

## Error Handling

- Service returns `Success` or `Failure` monad
- Errors are logged using `AppLogger`
- Transaction ensures data consistency
- If pay calculation fails, the error is logged but doesn't prevent work order approval

## Testing

Run the tests with:

```bash
rails test test/services/pay_calculation_services/process_work_order_service_test.rb
```

## Future Enhancements

Consider adding:

- Percentage-based deduction calculations (if needed beyond fixed amounts)
- Pay slip generation from PayCalculationDetail with deduction breakdown
- Export functionality for payroll systems
- Adjustment/correction mechanism for past calculations
- Email notifications when pay calculations are processed
- Admin interface for managing DeductionTypes
