# Pay Calculation System - Complete Guide

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Initial Setup](#initial-setup)
4. [Setting Up Deduction Types](#setting-up-deduction-types)
5. [Creating Pay Calculations](#creating-pay-calculations)
6. [Understanding Deductions](#understanding-deductions)
7. [Managing Pay Calculations](#managing-pay-calculations)
8. [Handling Government Tax Changes](#handling-government-tax-changes)
9. [Manual Recalculation Guide](#manual-recalculation-guide)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Pay Calculation system automatically calculates worker salaries based on completed work orders and applies Malaysian statutory deductions (EPF, SOCSO, SIP).

### Key Features

- ✅ **Automatic salary calculation** from completed work orders
- ✅ **Nationality-aware deductions** (Local vs Foreigner)
- ✅ **Percentage-based calculations** (not fixed amounts)
- ✅ **Immutable deductions** (frozen at creation time)
- ✅ **Historical accuracy** (past calculations never change)

### Key Concepts

- **Pay Calculation**: Container for one month's payroll (e.g., November 2025)
- **Pay Calculation Detail**: Individual worker's pay for that month
- **Deduction Type**: Rules for calculating deductions (EPF, SOCSO, SIP)
- **Employee Deductions**: Amount deducted from worker's salary
- **Employer Deductions**: Company's contribution (not deducted from salary)
- **Net Salary**: Gross Salary - Employee Deductions

---

## System Architecture

### Database Tables

```
pay_calculations
├── id
├── month_year (e.g., "2025-11")
├── total_gross_salary
├── total_deductions (employee deductions)
└── total_net_salary

pay_calculation_details
├── id
├── pay_calculation_id
├── worker_id
├── gross_salary (from completed work orders)
├── employee_deductions (deducted from salary)
├── employer_deductions (company cost)
├── net_salary (gross - employee_deductions)
├── deduction_breakdown (JSON)
└── currency

deduction_types
├── code (EPF, SOCSO_MALAYSIAN, etc.)
├── name
├── employee_contribution (percentage)
├── employer_contribution (percentage)
├── calculation_type (percentage)
├── applies_to_nationality (all, local, foreigner)
├── effective_from
├── effective_until
└── is_active
```

### Data Flow

```
Work Orders (completed)
    ↓
Calculate Gross Salary (sum of worker salaries)
    ↓
Apply Deductions (based on nationality and month)
    ↓
Calculate Net Salary (gross - employee deductions)
    ↓
Store in Pay Calculation Detail (immutable)
```

---

## Initial Setup

### Step 1: Seed Deduction Types

```bash
# Run the deduction types seed
docker compose exec web rails runner "load 'db/seeds/deduction_types.rb'"
```

This creates the Malaysian statutory deductions:

**EPF (Employees Provident Fund)**

- Employee: 11%
- Employer: 12%
- Applies to: All workers

**SOCSO Malaysian**

- Employee: 0.5%
- Employer: 1.75%
- Applies to: Local workers only

**SOCSO Foreign**

- Employee: 0%
- Employer: 1.25%
- Applies to: Foreigner workers only

**SIP (Employment Insurance)**

- Employee: 0.2%
- Employer: 0.2%
- Applies to: Local workers only

### Step 2: Verify Setup

Check what deductions are active:

```bash
docker compose exec web rails runner "
DeductionType.active_on(Date.current).each do |dt|
  puts \"#{dt.code}: #{dt.name}\"
  puts \"  Employee: #{dt.employee_contribution}% | Employer: #{dt.employer_contribution}%\"
  puts \"  Applies to: #{dt.applies_to_nationality || 'all'}\"
  puts
end
"
```

### Step 3: Configure Worker Nationalities

Ensure all workers have nationality set to either "Local" or "Foreigner":

```ruby
# In Rails console or via UI
Worker.find_each do |worker|
  if worker.nationality.blank?
    worker.update(nationality: 'Local')  # or 'Foreigner'
  end
end
```

---

## Setting Up Deduction Types

### Understanding Deduction Types

Deduction types define the rules for calculating statutory deductions (EPF, SOCSO, SIP, etc.). Each deduction type contains:

- **Code**: Unique identifier (e.g., "EPF", "SOCSO_MALAYSIAN")
- **Name**: Display name (e.g., "EPF (Employees Provident Fund)")
- **Employee Contribution**: Percentage deducted from worker's salary
- **Employer Contribution**: Percentage paid by company (not deducted from salary)
- **Calculation Type**: Always "percentage" for Malaysian statutory deductions
- **Applies To Nationality**: Filter by worker type (all/local/foreigner)
- **Effective From**: Start date for this rate
- **Effective Until**: End date (nil = currently active)
- **Is Active**: Whether this deduction is enabled

### Step-by-Step: Create New Deduction Type

**Example**: Government introduces new "Human Resource Development Fund" (HRDF) levy effective January 1, 2026.

**Via Rake Task (Recommended)**:

```bash
docker compose exec web rails deductions:create[HRDF,"Human Resource Development Fund",1.0,1.0,2026-01-01,"Monthly training levy for skill development"]
```

**Via Rails Console**:

```ruby
# Open Rails console
docker compose exec web rails console

# Create the deduction type
DeductionType.create!(
  code: 'HRDF',
  name: 'Human Resource Development Fund',
  description: 'Monthly training levy for skill development',
  employee_contribution: 1.0,      # 1% from employee
  employer_contribution: 1.0,       # 1% from employer
  calculation_type: 'percentage',
  applies_to_nationality: 'all',   # Applies to all workers
  is_active: true,
  effective_from: '2026-01-01',
  effective_until: nil              # Currently active
)
```

**Verify Creation**:

```ruby
# Check it exists
hrdf = DeductionType.find_by(code: 'HRDF')
puts "Created: #{hrdf.name}"
puts "Employee: #{hrdf.employee_contribution}%"
puts "Employer: #{hrdf.employer_contribution}%"
puts "Effective from: #{hrdf.effective_from}"

# Check it will be active in January 2026
active_jan_2026 = DeductionType.active_on(Date.parse('2026-01-01'))
                               .where(code: 'HRDF')
                               .exists?
puts "Active in Jan 2026: #{active_jan_2026}"
```

**What Happens Automatically**:

- ✅ All pay calculations created from January 2026 onwards will automatically include HRDF
- ✅ December 2025 and earlier months will NOT include HRDF (historical accuracy preserved)
- ✅ No code changes needed - system picks up new deduction automatically

### Step-by-Step: Deactivate Deduction Type

**Example**: Government suspends SIP deduction for 6 months.

```ruby
# Find the current SIP
sip = DeductionType.find_by(code: 'SIP', effective_until: nil)

# Deactivate it
sip.update!(is_active: false)

# Or end it with effective date
sip.update!(effective_until: '2025-12-31')
```

### Step-by-Step: Nationality-Specific Deductions

**Example**: Create different SOCSO rates for local vs foreign workers.

```ruby
# SOCSO for Local workers
DeductionType.create!(
  code: 'SOCSO_MALAYSIAN',
  name: 'SOCSO (Malaysian)',
  description: 'Social Security for local workers',
  employee_contribution: 0.5,
  employer_contribution: 1.75,
  calculation_type: 'percentage',
  applies_to_nationality: 'local',    # Only for local workers
  is_active: true,
  effective_from: '2025-01-01',
  effective_until: nil
)

# SOCSO for Foreign workers (different rates)
DeductionType.create!(
  code: 'SOCSO_FOREIGN',
  name: 'SOCSO (Foreign)',
  description: 'Social Security for foreign workers',
  employee_contribution: 0.0,          # Foreign workers don't pay
  employer_contribution: 1.25,
  calculation_type: 'percentage',
  applies_to_nationality: 'foreigner', # Only for foreign workers
  is_active: true,
  effective_from: '2025-01-01',
  effective_until: nil
)
```

---

## Creating Pay Calculations

### Automatic Creation via UI

1. Navigate to **Work Order → Pay Calculation**
2. Click **"Create Pay Calculation"**
3. Select month and year
4. System automatically:
   - Finds all completed work orders for that month
   - Groups by worker
   - Calculates gross salary (sum of worker salaries)
   - Applies deductions based on nationality
   - Calculates net salary

### Manual Creation via Console

```ruby
# Create pay calculation for November 2025
pay_calc = PayCalculation.find_or_create_for_month('2025-11')

# Find completed work orders for November
work_orders = WorkOrder.where(
  status: 'completed',
  completion_date: Date.parse('2025-11-01').beginning_of_month..Date.parse('2025-11-01').end_of_month
)

# Group by worker and calculate gross salary
work_orders.group_by(&:worker_id).each do |worker_id, orders|
  worker = Worker.find(worker_id)
  gross_salary = orders.sum(&:total_worker_salary)

  # Create pay calculation detail (deductions auto-calculated)
  pay_calc.pay_calculation_details.create!(
    worker: worker,
    gross_salary: gross_salary
  )
end

# Recalculate overall totals
pay_calc.recalculate_overall_total!
```

### What Happens Automatically

When a `PayCalculationDetail` is created:

1. **`before_create :apply_deductions`** runs
2. System queries `DeductionType.active_on('2025-11-01').for_nationality(worker.nationality.downcase)`
3. For each deduction type:
   - Calculates employee amount: `gross_salary * employee_contribution / 100`
   - Calculates employer amount: `gross_salary * employer_contribution / 100`
4. Stores breakdown in `deduction_breakdown` JSONB column
5. **`before_save :calculate_net_salary`** runs
6. Sets `net_salary = gross_salary - employee_deductions`

---

## Understanding Deductions

### Local Worker Example

**Worker**: Ahmad (Local)
**Gross Salary**: RM 3,000.00

**Deductions Applied**:

- EPF: RM 330.00 (11% of RM 3,000)
- SOCSO Malaysian: RM 15.00 (0.5% of RM 3,000)
- SIP: RM 6.00 (0.2% of RM 3,000)

**Totals**:

- Employee Deductions: RM 351.00
- Employer Deductions: RM 418.50 (EPF 12% + SOCSO 1.75% + SIP 0.2%)
- Net Salary: RM 2,649.00 (RM 3,000 - RM 351)

### Foreign Worker Example

**Worker**: Kumar (Foreigner)
**Gross Salary**: RM 3,000.00

**Deductions Applied**:

- EPF: RM 330.00 (11% of RM 3,000)
- SOCSO Foreign: RM 0.00 (0% for employee)

**Totals**:

- Employee Deductions: RM 330.00
- Employer Deductions: RM 397.50 (EPF 12% + SOCSO Foreign 1.25%)
- Net Salary: RM 2,670.00 (RM 3,000 - RM 330)

### Deduction Breakdown Structure

```json
{
  "EPF": {
    "name": "EPF (Employees Provident Fund)",
    "calculation_type": "percentage",
    "employee_rate": 11.0,
    "employer_rate": 12.0,
    "employee_amount": 330.0,
    "employer_amount": 360.0,
    "gross_salary": 3000.0,
    "nationality": "local",
    "applies_to_nationality": "all"
  },
  "SOCSO_MALAYSIAN": {
    "name": "SOCSO (Malaysian)",
    "calculation_type": "percentage",
    "employee_rate": 0.5,
    "employer_rate": 1.75,
    "employee_amount": 15.0,
    "employer_amount": 52.5,
    "gross_salary": 3000.0,
    "nationality": "local",
    "applies_to_nationality": "local"
  },
  "SIP": {
    "name": "SIP (Employment Insurance)",
    "calculation_type": "percentage",
    "employee_rate": 0.2,
    "employer_rate": 0.2,
    "employee_amount": 6.0,
    "employer_amount": 6.0,
    "gross_salary": 3000.0,
    "nationality": "local",
    "applies_to_nationality": "local"
  }
}
```

---

## Managing Pay Calculations

### Viewing Pay Calculations

**Via UI**:

1. Navigate to **Work Order → Pay Calculation**
2. Click on a specific month to view worker details
3. Click info icon next to worker to see detailed breakdown

**Via Console**:

```ruby
# List all pay calculations
PayCalculation.all.each do |pc|
  puts "#{pc.month_year}: #{pc.pay_calculation_details.count} workers, Total Net: RM #{pc.total_net_salary}"
end

# View specific pay calculation
pay_calc = PayCalculation.find_by(month_year: '2025-11')
puts "Total Gross: RM #{pay_calc.total_gross_salary}"
puts "Total Deductions: RM #{pay_calc.total_deductions}"
puts "Total Net: RM #{pay_calc.total_net_salary}"

# View worker details
pay_calc.pay_calculation_details.each do |detail|
  puts "\n#{detail.worker.name} (#{detail.worker.nationality})"
  puts "  Gross: RM #{detail.gross_salary}"
  puts "  Employee Deductions: RM #{detail.employee_deductions}"
  puts "  Employer Deductions: RM #{detail.employer_deductions}"
  puts "  Net Salary: RM #{detail.net_salary}"
end
```

### Updating Gross Salary

If a work order is corrected and gross salary needs updating:

```ruby
detail = PayCalculationDetail.find(123)

# Update gross salary
detail.update!(gross_salary: 3500)

# Deductions are IMMUTABLE - they don't auto-recalculate
# Net salary is recalculated: new_gross - old_employee_deductions

# To recalculate deductions (uses historical rates for that month):
detail.recalculate_deductions!
```

### Recalculating Deductions

**When to recalculate**:

- Gross salary was entered incorrectly
- Worker nationality was wrong
- Deduction data was corrupted

**How to recalculate**:

```ruby
# Single record
detail = PayCalculationDetail.find(123)
detail.recalculate_deductions!

# All records for a month
pay_calc = PayCalculation.find_by(month_year: '2025-11')
pay_calc.pay_calculation_details.find_each(&:recalculate_deductions!)
pay_calc.recalculate_overall_total!

# Using rake task
docker compose exec web rails pay_calculations:recalculate_month[2025-11]
```

**Important**: `recalculate_deductions!` uses the **historical rates** for that month, not current rates.

---

## Handling Government Tax Changes

This section covers how to handle real-world scenarios when the government changes tax rates or introduces new deductions.

### Scenario 1: EPF Rate Change (Common)

**Announcement**: Government announces EPF employee contribution decreases from 11% to 9% effective January 1, 2026.

**Important**: The system uses **effective dates** to ensure historical accuracy. December 2025 salaries will still use 11%, while January 2026 onwards will use 9%.

#### Step 1: Check Current Rate

```ruby
# Via console
current_epf = DeductionType.find_by(code: 'EPF', effective_until: nil)
puts "Current EPF Employee: #{current_epf.employee_contribution}%"
puts "Effective from: #{current_epf.effective_from}"
```

#### Step 2: Update Rate Using Rake Task (Recommended)

```bash
# Syntax: update_rate[CODE, employee%, employer%, effective_from]
docker compose exec web rails deductions:update_rate[EPF,9.0,12.0,2026-01-01]
```

**Output**:

```
✓ Successfully updated EPF deduction rate

Old rate (2025-01-01 to 2025-12-31):
  Employee: 11.0%, Employer: 12.0%

New rate (2026-01-01 onwards):
  Employee: 9.0%, Employer: 12.0%
```

#### Step 3: What Happens Behind the Scenes

```ruby
# The rake task does this automatically:

# 1. Find current EPF (the one with no end date)
old_epf = DeductionType.find_by(code: 'EPF', effective_until: nil)

# 2. Set its end date to day BEFORE new rate starts
old_epf.update!(effective_until: '2025-12-31')

# 3. Create NEW EPF record with new rate
DeductionType.create!(
  code: 'EPF',
  name: 'EPF (Employees Provident Fund)',
  description: 'Updated rate effective 2026',
  employee_contribution: 9.0,       # NEW RATE
  employer_contribution: 12.0,      # Unchanged
  calculation_type: 'percentage',
  applies_to_nationality: 'all',
  is_active: true,
  effective_from: '2026-01-01',     # NEW START DATE
  effective_until: nil              # Currently active
)
```

#### Step 4: Verify the Change

```bash
# View complete history
docker compose exec web rails deductions:history[EPF]
```

**Output**:

```
=== Deduction Rate History for EPF ===

[PAST] 2025-01-01 to 2025-12-31
  Employee: 11.0%, Employer: 12.0%
  Active: true

[CURRENT] 2026-01-01 to present
  Employee: 9.0%, Employer: 12.0%
  Active: true
```

#### Step 5: Test Different Months

```ruby
# Test December 2025 (should use old 11% rate)
dec_deductions = DeductionType.active_on(Date.parse('2025-12-15'))
dec_epf = dec_deductions.find_by(code: 'EPF')
puts "December 2025 EPF: #{dec_epf.employee_contribution}%"  # Shows: 11.0%

# Test January 2026 (should use new 9% rate)
jan_deductions = DeductionType.active_on(Date.parse('2026-01-15'))
jan_epf = jan_deductions.find_by(code: 'EPF')
puts "January 2026 EPF: #{jan_epf.employee_contribution}%"   # Shows: 9.0%
```

#### Step 6: Historical Pay Calculations Remain Unchanged

```ruby
# Pay calculations already created for December 2025
dec_calc = PayCalculation.find_by(month_year: '2025-12')
dec_detail = dec_calc.pay_calculation_details.first

# This will STILL show 11% because it's frozen
puts dec_detail.deduction_breakdown['EPF']['employee_rate']  # 11.0%

# This is CORRECT and EXPECTED - historical data never changes
```

### Scenario 2: New Tax Introduction

**Announcement**: Government introduces "Employment Insurance Levy" (EIL) of 0.5% (employee) and 0.5% (employer) effective July 1, 2026.

#### Step 1: Create New Deduction Type

```bash
docker compose exec web rails deductions:create[EIL,"Employment Insurance Levy",0.5,0.5,2026-07-01,"New government levy for employment insurance"]
```

#### Step 2: Verify Creation

```ruby
eil = DeductionType.find_by(code: 'EIL')
puts "Created: #{eil.name}"
puts "Employee: #{eil.employee_contribution}%"
puts "Effective from: #{eil.effective_from}"
```

#### Step 3: What Happens Automatically

```ruby
# Before July 2026 - Pay calculation shows 3 deductions (Local worker)
june_calc = PayCalculation.create!(month_year: '2026-06')
june_detail = june_calc.pay_calculation_details.create!(
  worker: local_worker,
  gross_salary: 3000
)
puts june_detail.deduction_breakdown.keys
# Output: ["EPF", "SOCSO_MALAYSIAN", "SIP"]  (No EIL)

# July 2026 onwards - Pay calculation shows 4 deductions (Local worker)
july_calc = PayCalculation.create!(month_year: '2026-07')
july_detail = july_calc.pay_calculation_details.create!(
  worker: local_worker,
  gross_salary: 3000
)
puts july_detail.deduction_breakdown.keys
# Output: ["EPF", "SOCSO_MALAYSIAN", "SIP", "EIL"]  (EIL included!)
```

### Scenario 3: Temporary Rate Suspension

**Announcement**: Government suspends SOCSO deductions for 6 months (Jan-Jun 2026) due to economic hardship.

#### Step 1: End Current SOCSO

```ruby
# Find current SOCSO for local workers
socso = DeductionType.find_by(code: 'SOCSO_MALAYSIAN', effective_until: nil)

# End it on December 31, 2025
socso.update!(effective_until: '2025-12-31')
```

#### Step 2: Create Suspended Period (0% rates)

```ruby
DeductionType.create!(
  code: 'SOCSO_MALAYSIAN',
  name: 'SOCSO (Malaysian) - SUSPENDED',
  description: 'Temporary suspension Jan-Jun 2026',
  employee_contribution: 0.0,      # SUSPENDED
  employer_contribution: 0.0,      # SUSPENDED
  calculation_type: 'percentage',
  applies_to_nationality: 'local',
  is_active: true,
  effective_from: '2026-01-01',
  effective_until: '2026-06-30'    # Ends June 30
)
```

#### Step 3: Create Resumption (July 1, 2026)

```ruby
DeductionType.create!(
  code: 'SOCSO_MALAYSIAN',
  name: 'SOCSO (Malaysian)',
  description: 'Resumed after suspension',
  employee_contribution: 0.5,      # RESUMED
  employer_contribution: 1.75,     # RESUMED
  calculation_type: 'percentage',
  applies_to_nationality: 'local',
  is_active: true,
  effective_from: '2026-07-01',
  effective_until: nil             # Currently active
)
```

#### Step 4: Verify Timeline

```bash
docker compose exec web rails deductions:history[SOCSO_MALAYSIAN]
```

**Output**:

```
=== Deduction Rate History for SOCSO_MALAYSIAN ===

[PAST] 2025-01-01 to 2025-12-31
  Employee: 0.5%, Employer: 1.75%

[PAST] 2026-01-01 to 2026-06-30
  Employee: 0.0%, Employer: 0.0%
  Description: Temporary suspension Jan-Jun 2026

[CURRENT] 2026-07-01 to present
  Employee: 0.5%, Employer: 1.75%
  Description: Resumed after suspension
```

### Scenario 4: Multiple Rate Changes at Once

**Announcement**: Government announces multiple changes effective January 1, 2027:

- EPF: 9% → 8% (employee)
- SIP: 0.2% → 0.3% (both)
- New tax: PCB 2% (employee only)

#### Use Batch Script

```ruby
# Create a script: tmp/update_rates_2027.rb
DeductionType.transaction do
  # Update EPF
  old_epf = DeductionType.find_by(code: 'EPF', effective_until: nil)
  old_epf.update!(effective_until: '2026-12-31')

  DeductionType.create!(
    code: 'EPF',
    name: 'EPF (Employees Provident Fund)',
    employee_contribution: 8.0,
    employer_contribution: 12.0,
    calculation_type: 'percentage',
    applies_to_nationality: 'all',
    is_active: true,
    effective_from: '2027-01-01',
    effective_until: nil
  )

  # Update SIP
  old_sip = DeductionType.find_by(code: 'SIP', effective_until: nil)
  old_sip.update!(effective_until: '2026-12-31')

  DeductionType.create!(
    code: 'SIP',
    name: 'SIP (Employment Insurance)',
    employee_contribution: 0.3,
    employer_contribution: 0.3,
    calculation_type: 'percentage',
    applies_to_nationality: 'local',
    is_active: true,
    effective_from: '2027-01-01',
    effective_until: nil
  )

  # Create new PCB tax
  DeductionType.create!(
    code: 'PCB',
    name: 'Potongan Cukai Bulanan',
    description: 'Monthly tax deduction',
    employee_contribution: 2.0,
    employer_contribution: 0.0,
    calculation_type: 'percentage',
    applies_to_nationality: 'all',
    is_active: true,
    effective_from: '2027-01-01',
    effective_until: nil
  )

  puts "✓ All rates updated for 2027"
end

# Run the script
docker compose exec web rails runner tmp/update_rates_2027.rb
```

### Important Rules

✅ **DO**:

- Always create NEW records for rate changes
- Set `effective_from` to the exact start date
- Set `effective_until` on old records to day BEFORE new rate
- Keep only ONE record per code with `effective_until: nil`
- Test rate changes in console before applying

❌ **DON'T**:

- Update `employee_contribution` or `employer_contribution` on existing records
- Delete old deduction records (breaks historical data)
- Set `effective_from` to past dates if pay calculations already exist
- Have overlapping effective date ranges for same code

---

## Manual Recalculation Guide

Sometimes you need to manually recalculate pay calculation details. This section covers when and how to do it safely.

### When to Recalculate

**Recalculate if**:

- ✅ Gross salary was entered incorrectly
- ✅ Worker nationality was wrong when pay calculation was created
- ✅ Deduction data was corrupted or incorrect
- ✅ Work orders were added/removed after pay calculation creation

**Do NOT recalculate if**:

- ❌ Government rates changed (historical data should stay accurate)
- ❌ You just want to see current calculations (use calculator service instead)
- ❌ Everything is working fine (don't fix what isn't broken)

### Method 1: Recalculate Single Worker

**Scenario**: Worker's nationality was set to "Foreigner" but should be "Local". Their November pay is missing SOCSO and SIP deductions.

#### Step 1: Identify the Problem

```ruby
# Find the worker
worker = Worker.find_by(name: 'Ahmad')
puts "Current nationality: #{worker.nationality}"  # Shows: Foreigner

# Find their pay detail for November
pay_calc = PayCalculation.find_by(month_year: '2025-11')
detail = pay_calc.pay_calculation_details.find_by(worker: worker)

puts "Current deductions: #{detail.deduction_breakdown.keys}"
# Shows: ["EPF"] (missing SOCSO and SIP)

puts "Employee Deductions: RM #{detail.employee_deductions}"
# Shows: RM 330.00 (should be RM 351.00 for local worker)
```

#### Step 2: Fix Worker Nationality

```ruby
# Update worker nationality
worker.update!(nationality: 'Local')
puts "Updated nationality: #{worker.nationality}"  # Shows: Local
```

#### Step 3: Recalculate Deductions

```ruby
# Recalculate using historical rates for November 2025
detail.recalculate_deductions!

# Verify the fix
detail.reload
puts "New deductions: #{detail.deduction_breakdown.keys}"
# Shows: ["EPF", "SOCSO_MALAYSIAN", "SIP"]

puts "New Employee Deductions: RM #{detail.employee_deductions}"
# Shows: RM 351.00 (correct!)

puts "New Net Salary: RM #{detail.net_salary}"
# Shows: RM 2,649.00 (gross RM 3,000 - deductions RM 351)
```

#### Step 4: Update Overall Total

```ruby
# Recalculate the month's total
pay_calc.recalculate_overall_total!

puts "Updated Total Net Salary: RM #{pay_calc.total_net_salary}"
```

### Method 2: Recalculate Entire Month

**Scenario**: Multiple workers in November have incorrect deductions due to data migration issue.

#### Step 1: Backup Current Data (Optional but Recommended)

```bash
# Export current data to CSV
docker compose exec web rails runner "
pay_calc = PayCalculation.find_by(month_year: '2025-11')
require 'csv'
CSV.open('tmp/november_backup.csv', 'w') do |csv|
  csv << ['Worker ID', 'Name', 'Gross', 'Employee Deductions', 'Net']
  pay_calc.pay_calculation_details.each do |d|
    csv << [d.worker_id, d.worker.name, d.gross_salary, d.employee_deductions, d.net_salary]
  end
end
puts 'Backup saved to tmp/november_backup.csv'
"
```

#### Step 2: Recalculate All Details

```bash
# Using rake task (recommended for entire month)
docker compose exec web rails pay_calculations:recalculate_month[2025-11]
```

**Output**:

```
Recalculating pay calculation details for 2025-11...
Updated: Worker ID 101 - Ahmad
Updated: Worker ID 102 - Siti
Updated: Worker ID 103 - Kumar
...

============================================================
Recalculation completed for 2025-11
Total records updated: 45
Total Gross Salary: RM 135,000.00
Total Deductions: RM 15,795.00
Total Net Salary: RM 119,205.00
============================================================
```

#### Step 3: Verify Results

```ruby
# Check a few workers manually
pay_calc = PayCalculation.find_by(month_year: '2025-11')

# Spot check worker 1
detail1 = pay_calc.pay_calculation_details.find_by(worker_id: 101)
puts "Worker 101: Gross=#{detail1.gross_salary}, Deductions=#{detail1.employee_deductions}, Net=#{detail1.net_salary}"

# Spot check worker 2
detail2 = pay_calc.pay_calculation_details.find_by(worker_id: 102)
puts "Worker 102: Gross=#{detail2.gross_salary}, Deductions=#{detail2.employee_deductions}, Net=#{detail2.net_salary}"

# Check totals match
total_net = pay_calc.pay_calculation_details.sum(:net_salary)
puts "Calculated Total: RM #{total_net}"
puts "Stored Total: RM #{pay_calc.total_net_salary}"
puts "Match: #{total_net == pay_calc.total_net_salary}"
```

### Method 3: Recalculate All Pay Calculations

**Scenario**: System-wide data corruption or migration requires recalculating ALL months.

⚠️ **WARNING**: This is a destructive operation. Only use if absolutely necessary!

#### Step 1: Backup ALL Data

```bash
# Full database backup
docker compose exec web rails runner "
require 'csv'

PayCalculation.all.each do |pc|
  CSV.open(\"tmp/backup_#{pc.month_year}.csv\", 'w') do |csv|
    csv << ['Worker ID', 'Name', 'Gross', 'Employee Deductions', 'Net']
    pc.pay_calculation_details.each do |d|
      csv << [d.worker_id, d.worker.name, d.gross_salary, d.employee_deductions, d.net_salary]
    end
  end
  puts \"Backed up #{pc.month_year}\"
end
"
```

#### Step 2: Run Full Recalculation

```bash
docker compose exec web rails pay_calculations:recalculate_all
```

**Output**:

```
Starting recalculation of all pay calculation details...

Progress: 50/150 processed...
Progress: 100/150 processed...
Progress: 150/150 processed...

============================================================
Recalculation completed!
Total records: 150
Successfully updated: 150
Errors: 0
============================================================

Recalculating overall totals for pay calculations...
Updated PayCalculation ID 14 (2025-11)
Updated PayCalculation ID 15 (2025-12)
...

All done! ✓
```

#### Step 3: Full Validation

```ruby
# Validate all months
PayCalculation.all.each do |pay_calc|
  # Check each detail
  pay_calc.pay_calculation_details.each do |detail|
    # Verify deduction count
    expected_count = detail.worker.nationality == 'Local' ? 3 : 2
    actual_count = detail.deduction_breakdown.size

    if actual_count != expected_count
      puts "⚠️  #{pay_calc.month_year} - Worker #{detail.worker.name}: Expected #{expected_count} deductions, got #{actual_count}"
    end

    # Verify net salary calculation
    calculated_net = detail.gross_salary - detail.employee_deductions
    if (detail.net_salary - calculated_net).abs > 0.01
      puts "⚠️  #{pay_calc.month_year} - Worker #{detail.worker.name}: Net salary mismatch"
    end
  end

  # Check overall total
  calculated_total = pay_calc.pay_calculation_details.sum(:net_salary)
  if (pay_calc.total_net_salary - calculated_total).abs > 0.01
    puts "⚠️  #{pay_calc.month_year}: Overall total mismatch"
  else
    puts "✓ #{pay_calc.month_year}: All checks passed"
  end
end
```

### Method 4: Recalculate with Custom Logic

**Scenario**: Need to recalculate but with special handling (e.g., exclude certain workers).

```ruby
# Custom recalculation script
pay_calc = PayCalculation.find_by(month_year: '2025-11')

pay_calc.pay_calculation_details.each do |detail|
  # Skip certain workers if needed
  next if detail.worker.name == 'Special Case Worker'

  # Custom validation before recalculation
  if detail.gross_salary <= 0
    puts "Skipping #{detail.worker.name}: Zero or negative gross salary"
    next
  end

  # Recalculate
  puts "Recalculating #{detail.worker.name}..."
  detail.recalculate_deductions!

  # Custom post-calculation logic
  if detail.employee_deductions > detail.gross_salary
    puts "⚠️  WARNING: Deductions exceed gross salary for #{detail.worker.name}"
  end
end

# Update overall total
pay_calc.recalculate_overall_total!
puts "Done!"
```

### Understanding What Recalculate Does

When you call `recalculate_deductions!`, the system:

1. **Queries historical rates** for that specific month

   ```ruby
   # For November 2025, it queries:
   DeductionType.active_on(Date.parse('2025-11-01'))
                .for_nationality(worker.nationality.downcase)
   ```

2. **Calculates fresh deductions** using those rates

   ```ruby
   # For each deduction type:
   employee_amount = gross_salary * employee_contribution / 100
   employer_amount = gross_salary * employer_contribution / 100
   ```

3. **Updates the record** with new values

   ```ruby
   detail.update_columns(
     employee_deductions: new_employee_total,
     employer_deductions: new_employer_total,
     deduction_breakdown: new_breakdown,
     net_salary: gross_salary - new_employee_total,
     updated_at: Time.current
   )
   ```

4. **Preserves historical accuracy** by using that month's rates, NOT current rates

### Troubleshooting Recalculation Issues

#### Issue: Recalculation gives different result than original

**This is expected if**:

- Worker nationality changed
- Deduction types were added/removed
- Rates changed (but recalculation uses historical rates)

**Check**:

```ruby
# Compare original vs recalculated
detail = PayCalculationDetail.find(123)
original_deductions = detail.employee_deductions

detail.recalculate_deductions!
new_deductions = detail.employee_deductions

puts "Original: RM #{original_deductions}"
puts "Recalculated: RM #{new_deductions}"
puts "Difference: RM #{(new_deductions - original_deductions).abs}"
```

#### Issue: Recalculation fails with error

**Common errors**:

```ruby
# Missing month_year
# Solution: Ensure pay_calculation has month_year set

# Invalid nationality
# Solution: Ensure worker.nationality is "Local" or "Foreigner"

# No active deductions
# Solution: Check DeductionType.active_on(date) returns results
```

#### Issue: After recalculation, totals don't match

**Fix**:

```ruby
# Always recalculate overall total after detail updates
pay_calc.recalculate_overall_total!
```

### Best Practices for Recalculation

✅ **DO**:

- Backup data before bulk recalculation
- Test on a single record first
- Verify results after recalculation
- Recalculate overall totals after detail updates
- Document why you're recalculating

❌ **DON'T**:

- Recalculate without understanding the root cause
- Skip validation after recalculation
- Recalculate in production without testing first
- Forget to update overall totals

---

## Managing Deduction Types

### Viewing Active Deductions

```bash
# Via rake task
docker compose exec web rails deductions:active_for_month[2025-11]

# Via console
DeductionType.active_on(Date.parse('2025-11-01')).each do |dt|
  puts "#{dt.code}: Employee #{dt.employee_contribution}% | Employer #{dt.employer_contribution}%"
end
```

### Updating Deduction Rates

**Scenario**: Government announces EPF employee contribution decreases from 11% to 9% effective January 1, 2026.

**Steps**:

```bash
# Using rake task (recommended)
docker compose exec web rails deductions:update_rate[EPF,9.0,12.0,2026-01-01]
```

**What this does**:

1. Finds current EPF (with `effective_until: nil`)
2. Sets its `effective_until` to `2025-12-31`
3. Creates new EPF with `effective_from: 2026-01-01`

**Manual method**:

```ruby
# 1. End current rate
current_epf = DeductionType.find_by(code: 'EPF', effective_until: nil)
current_epf.update!(effective_until: '2025-12-31')

# 2. Create new rate
DeductionType.create!(
  code: 'EPF',
  name: 'EPF (Employees Provident Fund)',
  description: 'Updated rate effective 2026',
  employee_contribution: 9.0,
  employer_contribution: 12.0,
  calculation_type: 'percentage',
  applies_to_nationality: 'all',
  is_active: true,
  effective_from: '2026-01-01',
  effective_until: nil
)
```

### Viewing Rate History

```bash
# Via rake task
docker compose exec web rails deductions:history[EPF]

# Via console
DeductionType.where(code: 'EPF').order(:effective_from).each do |dt|
  period = "#{dt.effective_from} to #{dt.effective_until || 'present'}"
  puts "#{period}: Employee #{dt.employee_contribution}% | Employer #{dt.employer_contribution}%"
end
```

### Creating New Deduction Types

```bash
# Using rake task
docker compose exec web rails deductions:create[HRDF,"Human Resource Development Fund",1.0,1.0,2026-01-01,"Training levy"]

# Via console
DeductionType.create!(
  code: 'HRDF',
  name: 'Human Resource Development Fund',
  description: 'Training levy',
  employee_contribution: 1.0,
  employer_contribution: 1.0,
  calculation_type: 'percentage',
  applies_to_nationality: 'all',
  is_active: true,
  effective_from: '2026-01-01',
  effective_until: nil
)
```

---

## Troubleshooting

### Net Salary Displays Wrong Value

**Problem**: Net salary shows incorrect amount (e.g., RM 92.26 instead of RM 916.78)

**Cause**: Stored `net_salary` value in database is incorrect (usually after migrations or data changes)

**Solution**: The views now calculate net salary on-the-fly instead of using stored value:

```erb
<!-- Correct implementation -->
<%= number_with_precision(detail.gross_salary - detail.employee_deductions, precision: 2) %>
```

If you need to fix stored values:

```bash
docker compose exec web rails pay_calculations:recalculate_all
```

### Missing Deductions for Worker

**Problem**: Worker shows only 1 deduction (EPF) instead of 3 (EPF, SOCSO, SIP)

**Possible Causes**:

1. Worker nationality is not set or incorrect
2. Worker nationality doesn't match deduction type filters
3. Deduction types are not active for that month

**Check**:

```ruby
worker = Worker.find(102)
puts "Nationality: #{worker.nationality}"  # Should be "Local" or "Foreigner"

# Check what deductions apply
DeductionType.active_on(Date.parse('2025-11-01'))
             .for_nationality(worker.nationality.downcase)
             .each do |dt|
  puts "#{dt.code}: #{dt.name}"
end
```

**Fix**:

```ruby
# Fix worker nationality
worker.update(nationality: 'Local')

# Recalculate their pay
detail = PayCalculationDetail.find_by(worker: worker, pay_calculation: pay_calc)
detail.recalculate_deductions!
```

### Deduction Calculations Seem Wrong

**Check the math**:

```ruby
detail = PayCalculationDetail.find(123)
puts "Gross Salary: RM #{detail.gross_salary}"
puts "Nationality: #{detail.worker.nationality}"

# Expected deductions
result = PayCalculationServices::DeductionCalculator.calculate(
  detail.pay_calculation.month_year,
  gross_salary: detail.gross_salary,
  nationality: detail.worker.nationality.downcase
)

puts "\nExpected Employee Deductions: RM #{result.employee_deduction}"
puts "Actual Employee Deductions: RM #{detail.employee_deductions}"
puts "Match: #{result.employee_deduction == detail.employee_deductions}"

# View breakdown
result.deduction_breakdown.each do |code, data|
  puts "\n#{code}:"
  puts "  Employee Rate: #{data['employee_rate']}%"
  puts "  Employee Amount: RM #{data['employee_amount']}"
  puts "  Calculation: #{detail.gross_salary} × #{data['employee_rate']}% = #{data['employee_amount']}"
end
```

### Pay Calculation Only Shows Completed Work Orders

**This is correct behavior**. Pay calculations only include work orders with `status: 'completed'`.

**Check**:

```ruby
# Work orders for a worker in November 2025
worker = Worker.find(102)
all_orders = worker.work_orders.where(
  completion_date: Date.parse('2025-11-01').beginning_of_month..Date.parse('2025-11-01').end_of_month
)

completed_orders = all_orders.where(status: 'completed')

puts "Total work orders in November: #{all_orders.count}"
puts "Completed work orders: #{completed_orders.count}"
puts "Used in pay calculation: #{completed_orders.count}"
```

---

## Best Practices

### DO ✅

- Always set worker nationality to "Local" or "Foreigner"
- Only create pay calculations for completed work orders
- Use rake tasks for deduction rate updates
- Verify calculations before finalizing payroll
- Keep deduction type history (don't delete old records)
- Test rate changes in console before applying

### DON'T ❌

- Manually update `employee_deductions` or `employer_deductions` fields
- Delete deduction type records (breaks audit trail)
- Have multiple deduction types with same code and `effective_until: nil`
- Recalculate all pay calculations without good reason
- Change deduction rates without creating new records

### Validation Checklist

Before finalizing monthly payroll:

```ruby
pay_calc = PayCalculation.find_by(month_year: '2025-11')

# 1. Check all workers have nationality
pay_calc.pay_calculation_details.includes(:worker).each do |detail|
  if detail.worker.nationality.blank?
    puts "⚠️  Worker #{detail.worker.name} missing nationality"
  end
end

# 2. Verify deduction counts
pay_calc.pay_calculation_details.each do |detail|
  count = detail.deduction_breakdown.size
  expected = detail.worker.nationality == 'Local' ? 3 : 2
  if count != expected
    puts "⚠️  Worker #{detail.worker.name} has #{count} deductions, expected #{expected}"
  end
end

# 3. Check net salary calculations
pay_calc.pay_calculation_details.each do |detail|
  calculated_net = detail.gross_salary - detail.employee_deductions
  if (detail.net_salary - calculated_net).abs > 0.01
    puts "⚠️  Worker #{detail.worker.name} net salary mismatch"
  end
end

# 4. Verify totals
total_gross = pay_calc.pay_calculation_details.sum(:gross_salary)
total_deductions = pay_calc.pay_calculation_details.sum(:employee_deductions)
total_net = pay_calc.pay_calculation_details.sum(:net_salary)

puts "\n✓ Total Gross: RM #{total_gross}"
puts "✓ Total Deductions: RM #{total_deductions}"
puts "✓ Total Net: RM #{total_net}"
puts "✓ Workers: #{pay_calc.pay_calculation_details.count}"
```

---

## Rake Tasks Reference

### Pay Calculation Tasks

```bash
# Recalculate all pay calculation details
docker compose exec web rails pay_calculations:recalculate_all

# Recalculate specific month
docker compose exec web rails pay_calculations:recalculate_month[2025-11]
```

### Deduction Management Tasks

```bash
# View active deductions for a month
docker compose exec web rails deductions:active_for_month[2025-11]

# View deduction rate history
docker compose exec web rails deductions:history[EPF]

# Update deduction rate
docker compose exec web rails deductions:update_rate[EPF,9.0,12.0,2026-01-01]

# Create new deduction type
docker compose exec web rails deductions:create[CODE,"Name",employee%,employer%,effective_from,"Description"]
```

---

## Summary

The Pay Calculation system:

1. ✅ Automatically calculates salaries from completed work orders
2. ✅ Applies percentage-based deductions based on worker nationality
3. ✅ Stores immutable snapshots for historical accuracy
4. ✅ Supports rate changes through effective date management
5. ✅ Provides tools for corrections and recalculations

**Key Formula**: Net Salary = Gross Salary - Employee Deductions

**Malaysian Statutory Deductions**:

- Local Workers: EPF (11%) + SOCSO (0.5%) + SIP (0.2%) = 11.7% total
- Foreign Workers: EPF (11%) + SOCSO (0%) = 11% total

The system is production-ready and handles all Malaysian payroll requirements! 🎉
