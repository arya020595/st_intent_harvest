# Pay Calculation Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        WORK ORDER LIFECYCLE                          │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │ ongoing  │
    └────┬─────┘
         │ mark_complete
         ▼
    ┌──────────┐
    │ pending  │
    └────┬─────┘
         │ approve
         ▼
    ┌──────────┐        ┌────────────────────────────────────────┐
    │completed │───────▶│ Trigger Pay Calculation Process        │
    └──────────┘        └───────────┬────────────────────────────┘
                                    │
                                    ▼
        ┌───────────────────────────────────────────────────────────┐
        │  PayCalculationServices::ProcessWorkOrderService          │
        └───────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
        ┌──────────────────┐   ┌────────┐   ┌────────────────┐
        │  Extract Month   │   │Process │   │   Calculate    │
        │  (YYYY-MM from   │──▶│Workers │──▶│ Overall Total  │
        │   created_at)    │   │        │   │                │
        └──────────────────┘   └────────┘   └────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼                               ▼
        ┌─────────────────────────┐   ┌─────────────────────────┐
        │   PayCalculation        │   │ PayCalculationDetail    │
        │   - month_year: 2025-01 │   │ - worker_id             │
        │   - overall_total: 2500 │◀──│ - gross_salary: 2333.40 │
        └─────────────────────────┘   │ - worker_deductions:    │
                                      │   21.25 (auto)          │
                                      │ - employee_deductions:  │
                                      │   74.35 (auto)          │
                                      │ - net_salary: 2312.15   │
                                      │   (auto-calculated)     │
                                      │ - deduction_breakdown:  │
                                      │   {SOCSO: {...}}        │
                                      └─────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        CALCULATION LOGIC                             │
└─────────────────────────────────────────────────────────────────────┘

For each WorkOrderWorker in the completed Work Order:

┌────────────────────────────────────────────────────────────────┐
│ IF work_order_rate_type = "work_days"                         │
│                                                                │
│   gross_salary = work_days × rate                             │
│                                                                │
│   Example: 20 days × RM 50/day = RM 1,000                     │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ ELSE (normal or resources)                                     │
│                                                                │
│   gross_salary = work_area_size × rate                        │
│                                                                │
│   Example: 100 m² × RM 10/m² = RM 1,000                       │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ THEN (before save - automatic deduction calculation)          │
│                                                                │
│   1. Calculate deductions from active DeductionTypes          │
│   2. worker_deductions = SUM(DeductionType.worker_amount)     │
│   3. employee_deductions = SUM(DeductionType.employee_amount) │
│   4. net_salary = gross_salary - worker_deductions            │
│                                                                │
│   Example: RM 2,333.40 - RM 21.25 (SOCSO) = RM 2,312.15      │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ ACCUMULATION (same worker, same month)                         │
│                                                                │
│   Work Order 1: gross_salary = RM 1,000                       │
│   Work Order 2: gross_salary = RM 500                         │
│   ───────────────────────────────────────                     │
│   Total gross_salary = RM 1,500                               │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ OVERALL TOTAL (per month)                                      │
│                                                                │
│   overall_total = SUM(all net_salary in month)                │
│                                                                │
│   Worker A: RM 900 net                                        │
│   Worker B: RM 750 net                                        │
│   Worker C: RM 850 net                                        │
│   ───────────────────────────────────────                     │
│   Overall Total: RM 2,500                                     │
└────────────────────────────────────────────────────────────────┘
```

## Example Scenario

### Work Order Details:

- Created: 2025-01-15
- Approved: 2025-01-20
- Rate Type: normal
- Workers:
  - Worker A: 100 m² × RM 10/m² = RM 1,000
  - Worker B: 50 m² × RM 15/m² = RM 750

### Result:

**PayCalculation (month_year: "2025-01")**

```
overall_total: RM 1,707.50 (978.75 + 728.75)
```

**PayCalculationDetails:**

```
Worker A:
  gross_salary: RM 1,000
  worker_deductions: RM 21.25 (SOCSO)
  employee_deductions: RM 74.35 (SOCSO)
  net_salary: RM 978.75

Worker B:
  gross_salary: RM 750
  worker_deductions: RM 21.25 (SOCSO)
  employee_deductions: RM 74.35 (SOCSO)
  net_salary: RM 728.75
```

### Later in the same month (2025-01-25):

Another work order is approved with Worker A earning RM 500 more.

**Updated PayCalculationDetail for Worker A:**

```
Worker A:
  gross_salary: RM 1,500  (1,000 + 500)
  worker_deductions: RM 21.25 (SOCSO)
  employee_deductions: RM 74.35 (SOCSO)
  net_salary: RM 1,478.75
```

**Updated PayCalculation:**

```
overall_total: RM 2,207.50  (1,478.75 + 728.75)
```
