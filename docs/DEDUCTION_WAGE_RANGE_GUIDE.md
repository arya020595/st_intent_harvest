# Deduction Wage Range Implementation Guide

## Overview

This implementation adds support for wage range-based deduction calculations while refactoring the deduction system to follow Clean Code and SOLID principles. The solution uses **Strategy Pattern** and **Factory Pattern** to achieve clean separation of concerns.

## Business Requirement

Malaysian SOCSO (Social Security Organization) has two calculation methods:

1. **Local Workers**: Use wage range table with fixed amounts

   - Example: Salary RM 3,500 → Employee: RM 17.25, Employer: RM 60.35

2. **Foreign Workers**: Use percentage calculation (1.25% each)
   - Example: Salary RM 3,500 → Employee: RM 43.75, Employer: RM 43.75

## Architecture

### Strategy Pattern Implementation

```
DeductionType (Data Model)
    ↓
    delegates to
    ↓
DeductionCalculators::Factory (Factory Pattern)
    ↓
    creates
    ↓
Concrete Calculator (Strategy Pattern)
    ├── PercentageCalculator
    ├── FixedCalculator
    └── WageRangeCalculator
```

### SOLID Principles Applied

1. **Single Responsibility Principle (SRP)**

   - `DeductionType`: Pure data model, no calculation logic
   - `PercentageCalculator`: Only percentage calculations
   - `FixedCalculator`: Only fixed amount calculations
   - `WageRangeCalculator`: Only wage range lookups
   - `Factory`: Only calculator creation

2. **Open/Closed Principle (OCP)**

   - Add new calculation types without modifying existing code
   - Just create new calculator class and register in factory

3. **Liskov Substitution Principle (LSP)**

   - All calculators are interchangeable through `Base` interface
   - `calculate(gross_salary, field:)` method signature is consistent

4. **Interface Segregation Principle (ISP)**

   - Simple, focused calculator interface
   - Clients only depend on methods they use

5. **Dependency Inversion Principle (DIP)**
   - `DeductionType` depends on abstraction (`Factory`), not concrete calculators
   - Calculators depend on `Base` abstraction

## Database Schema

### deduction_wage_ranges Table

```sql
CREATE TABLE deduction_wage_ranges (
  id                   BIGINT PRIMARY KEY,
  deduction_type_id    BIGINT NOT NULL REFERENCES deduction_types(id) ON DELETE CASCADE,
  min_wage             NUMERIC(10,2) NOT NULL,
  max_wage             NUMERIC(10,2),  -- NULL means "and above"
  employee_amount      NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
  employer_amount      NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
  employee_percentage  NUMERIC(5,2) DEFAULT 0.0 NOT NULL,
  employer_percentage  NUMERIC(5,2) DEFAULT 0.0 NOT NULL,
  calculation_method   VARCHAR DEFAULT 'fixed' NOT NULL,  -- 'fixed' or 'percentage'
  created_at           TIMESTAMP NOT NULL,
  updated_at           TIMESTAMP NOT NULL
);

-- Constraints
ALTER TABLE deduction_wage_ranges
  ADD CONSTRAINT calculation_method_check
  CHECK (calculation_method IN ('fixed', 'percentage'));

ALTER TABLE deduction_wage_ranges
  ADD CONSTRAINT max_wage_check
  CHECK (max_wage IS NULL OR max_wage >= min_wage);

-- Unique index to prevent overlapping ranges
CREATE UNIQUE INDEX idx_wage_ranges_unique
  ON deduction_wage_ranges (deduction_type_id, min_wage, COALESCE(max_wage, 999999999));

-- Performance index for salary lookups
CREATE INDEX idx_wage_ranges_salary_lookup
  ON deduction_wage_ranges (deduction_type_id, min_wage, max_wage);
```

## File Structure

```
app/
├── models/
│   ├── deduction_type.rb                    # Updated with wage_range support
│   └── deduction_wage_range.rb              # New model for wage ranges
├── services/
│   └── deduction_calculators/               # New directory
│       ├── base.rb                          # Abstract base calculator
│       ├── percentage_calculator.rb         # Percentage strategy
│       ├── fixed_calculator.rb              # Fixed amount strategy
│       ├── wage_range_calculator.rb         # Wage range strategy
│       └── factory.rb                       # Factory for calculator creation
db/
├── migrate/
│   └── 20251211094024_create_deduction_wage_ranges.rb
└── seeds/
    └── production/
        └── deduction_wage_ranges.rb         # SOCSO wage range data
```

## Usage Examples

### Basic Calculation

```ruby
# Local worker (wage range)
socso_local = DeductionType.find_by(code: 'SOCSO_LOCAL')
employee_amount = socso_local.calculate_amount(3500, field: :employee_contribution)
# => 17.25

# Foreign worker (percentage)
socso_foreign = DeductionType.find_by(code: 'SOCSO_FOREIGN')
employee_amount = socso_foreign.calculate_amount(3500, field: :employee_contribution)
# => 43.75
```

### Direct Calculator Usage

```ruby
deduction_type = DeductionType.find_by(code: 'SOCSO_LOCAL')
calculator = DeductionCalculators::Factory.for(deduction_type)
# => #<DeductionCalculators::WageRangeCalculator>

amount = calculator.calculate(3500, field: :employee_contribution)
# => 17.25
```

### Query Wage Ranges

```ruby
socso = DeductionType.find_by(code: 'SOCSO_LOCAL')

# Find range for specific salary
range = socso.deduction_wage_ranges.for_salary(3500).first
# => #<DeductionWageRange min_wage: 3400.01, max_wage: 3500.00>

range.wage_range_display
# => "RM 3400.01 - RM 3500.00"

range.calculate_for(3500, field: :employee)
# => 17.25
```

## Testing

### Console Testing

```bash
docker compose exec web bin/rails console

# Test wage range calculation
socso = DeductionType.find_by(code: 'SOCSO_LOCAL')
[1500, 2500, 3500, 4500].each do |salary|
  employee = socso.calculate_amount(salary, field: :employee_contribution)
  employer = socso.calculate_amount(salary, field: :employer_contribution)
  puts "Salary: RM #{salary} → Employee: RM #{employee} | Employer: RM #{employer}"
end

# Verify architecture
DeductionCalculators::Factory.supported_types
# => ["percentage", "fixed", "wage_range"]

DeductionCalculators::Factory.for(socso).class.name
# => "DeductionCalculators::WageRangeCalculator"
```

### Unit Tests (Recommended)

```ruby
# test/services/deduction_calculators/wage_range_calculator_test.rb
require 'test_helper'

class DeductionCalculators::WageRangeCalculatorTest < ActiveSupport::TestCase
  setup do
    @deduction_type = deduction_types(:socso_local)
    @calculator = DeductionCalculators::WageRangeCalculator.new(@deduction_type)
  end

  test "calculates employee contribution for salary in range" do
    amount = @calculator.calculate(3500, field: :employee_contribution)
    assert_equal BigDecimal('17.25'), amount
  end

  test "returns zero when no range matches" do
    amount = @calculator.calculate(0, field: :employee_contribution)
    assert_equal BigDecimal('0'), amount
  end
end
```

## Adding New Calculation Types

To add a new calculation method (e.g., tiered percentage):

1. **Create Calculator Class**

```ruby
# app/services/deduction_calculators/tiered_percentage_calculator.rb
module DeductionCalculators
  class TieredPercentageCalculator < Base
    def calculate(gross_salary, field: :employee_contribution)
      # Your tiered logic here
    end
  end
end
```

2. **Register in Factory**

```ruby
# app/services/deduction_calculators/factory.rb
CALCULATORS = {
  'percentage' => PercentageCalculator,
  'fixed' => FixedCalculator,
  'wage_range' => WageRangeCalculator,
  'tiered_percentage' => TieredPercentageCalculator  # Add this
}.freeze
```

3. **Update Model Constant**

```ruby
# app/models/deduction_type.rb
CALCULATION_TYPES = %w[percentage fixed wage_range tiered_percentage].freeze
```

That's it! No changes to existing calculators or DeductionType logic needed.

## Data Integrity

### Database Constraints

1. **calculation_method_check**: Ensures only 'fixed' or 'percentage' values
2. **max_wage_check**: Ensures max_wage >= min_wage
3. **idx_wage_ranges_unique**: Prevents overlapping wage ranges
4. **CASCADE delete**: Deletes wage ranges when deduction type is deleted

### Model Validations

```ruby
validates :min_wage, presence: true, numericality: { greater_than_or_equal_to: 0 }
validates :max_wage, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
validate :max_wage_greater_than_or_equal_to_min_wage
```

## Performance Considerations

1. **Composite Index**: Fast salary lookups using `(deduction_type_id, min_wage, max_wage)`
2. **Scope Optimization**: `.for_salary` uses efficient WHERE conditions
3. **Calculator Memoization**: `@calculator ||=` prevents repeated factory calls
4. **Eager Loading**: Use `.includes(:deduction_wage_ranges)` for batch processing

## Migration Commands

```bash
# Run migration
docker compose exec web bin/rails db:migrate

# Seed SOCSO data
docker compose exec web bin/rails runner "load 'db/seeds/production/deduction_wage_ranges.rb'"

# Verify
docker compose exec web bin/rails runner "
  socso = DeductionType.find_by(code: 'SOCSO_LOCAL')
  puts socso.deduction_wage_ranges.count
"
```

## Benefits

### Code Quality

- ✅ Clean separation of concerns
- ✅ Easy to test (each calculator in isolation)
- ✅ Self-documenting code
- ✅ No god objects or long methods

### Maintainability

- ✅ Add new types without modifying existing code (OCP)
- ✅ Each class has single responsibility (SRP)
- ✅ Clear calculator interface (ISP)
- ✅ Minimal coupling between components

### Extensibility

- ✅ Support future requirements (tiered rates, conditional logic)
- ✅ Easy to add validation rules
- ✅ Pluggable calculator architecture
- ✅ Database-level data integrity

## Related Documentation

- [CLEAN CODE by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Design Patterns: Strategy Pattern](https://refactoring.guru/design-patterns/strategy)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Rails Service Objects](https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial)

## Contributors

- Architecture: Designed following Clean Code and SOLID principles
- Implemented: December 11, 2025
- Code Review: Verified with SOLID principles checklist

---

**Remember**: "Clean code is simple and direct. Clean code reads like well-written prose." — Robert C. Martin
