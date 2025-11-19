# TDD and Testing Guide

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [TDD Workflow](#tdd-workflow)
- [Writing Tests](#writing-tests)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project uses **Minitest** as the testing framework with Rails 8.1. Tests follow the TDD (Test-Driven Development) approach to ensure code quality and maintainability.

### Test Types

- **Model Tests** - Test business logic, validations, associations, and callbacks
- **Controller Tests** - Test request/response cycles, authorization, and routing
- **Service Tests** - Test service objects and business operations
- **System Tests** - Test user workflows end-to-end
- **Integration Tests** - Test component interactions

---

## Test Structure

```
test/
├── fixtures/               # Test data (YAML)
│   ├── deduction_types.yml
│   ├── workers.yml
│   ├── pay_calculations.yml
│   └── pay_calculation_details.yml
├── models/                 # Model tests
│   ├── worker_test.rb
│   ├── pay_calculation_test.rb
│   └── pay_calculation_detail_test.rb
├── controllers/            # Controller tests
│   ├── workers_controller_test.rb
│   └── work_order/
│       └── pay_calculations_controller_test.rb
├── services/              # Service tests
│   └── pay_calculation_services/
│       ├── process_work_order_service_test.rb
│       └── worker_pay_calculator_test.rb
├── system/                # Browser-based tests
├── integration/           # Integration tests
├── helpers/               # Helper tests
└── test_helper.rb         # Test configuration

```

---

## Running Tests

### Basic Commands

```bash
# Run all tests
docker compose exec web rails test

# Run all tests with verbose output
docker compose exec web rails test -v

# Run specific test file
docker compose exec web rails test test/models/worker_test.rb

# Run specific test by name
docker compose exec web rails test test/models/worker_test.rb -n test_should_be_valid

# Run all tests in a directory
docker compose exec web rails test test/models/
docker compose exec web rails test test/services/pay_calculation_services/

# Run tests matching a pattern
docker compose exec web rails test test/models/*pay*

# Run tests with seed (for reproducibility)
docker compose exec web rails test --seed 12345
```

### Running Tests in Parallel

```bash
# Run tests in parallel (faster for large test suites)
docker compose exec web rails test -j 4
```

### Running System Tests (with browser)

```bash
# Run system tests
docker compose exec web rails test:system

# Run specific system test
docker compose exec web rails test test/system/workers_test.rb
```

### Filtering Tests

```bash
# Run only failures from last run
docker compose exec web rails test --fail-fast

# Stop on first failure
docker compose exec web rails test --verbose --fail-fast
```

---

## TDD Workflow

### Red-Green-Refactor Cycle

```
┌─────────────────────────────────────────┐
│ 1. RED: Write a failing test           │
│    - Test describes desired behavior   │
│    - Run test → Should FAIL            │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│ 2. GREEN: Write minimal code to pass   │
│    - Implement just enough logic       │
│    - Run test → Should PASS            │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│ 3. REFACTOR: Improve code quality      │
│    - Clean up duplication              │
│    - Improve naming                    │
│    - Run test → Should still PASS      │
└──────────────┬──────────────────────────┘
               ↓
            REPEAT
```

### Example TDD Session

#### Step 1: Write the Test (RED)

```ruby
# test/models/pay_calculation_detail_test.rb
test 'should calculate net salary correctly' do
  detail = PayCalculationDetail.create!(
    pay_calculation: @pay_calc,
    worker: @worker,
    gross_salary: 5000.00
  )

  # Test fails because logic not implemented yet
  assert_equal 4978.75, detail.net_salary
end
```

Run: `docker compose exec web rails test test/models/pay_calculation_detail_test.rb -n test_should_calculate_net_salary_correctly`

**Expected:** ❌ FAIL (method doesn't exist or returns wrong value)

#### Step 2: Implement Code (GREEN)

```ruby
# app/models/pay_calculation_detail.rb
before_save :calculate_net_salary

private

def calculate_net_salary
  self.net_salary = (gross_salary || 0) - employee_deductions
end
```

Run test again: `docker compose exec web rails test test/models/pay_calculation_detail_test.rb -n test_should_calculate_net_salary_correctly`

**Expected:** ✅ PASS

#### Step 3: Refactor (if needed)

Improve code quality while keeping tests green.

---

## Writing Tests

### Model Test Template

```ruby
require 'test_helper'

class WorkerTest < ActiveSupport::TestCase
  # Load only needed fixtures
  fixtures :workers, :work_orders

  def setup
    @worker = workers(:one)
  end

  # Test validations
  test 'should require name' do
    worker = Worker.new(worker_type: 'Full - Time')
    assert_not worker.valid?
    assert_includes worker.errors[:name], "can't be blank"
  end

  # Test associations
  test 'should have many work_order_workers' do
    assert_respond_to @worker, :work_order_workers
    assert_kind_of ActiveRecord::Associations::CollectionProxy,
                   @worker.work_order_workers
  end

  # Test instance methods
  test 'should calculate total earnings' do
    result = @worker.calculate_monthly_earnings('2025-11')
    assert_instance_of BigDecimal, result
    assert result >= 0
  end

  # Test scopes
  test 'active scope should return only active workers' do
    active_workers = Worker.active
    assert active_workers.all?(&:is_active)
  end
end
```

### Service Test Template

```ruby
require 'test_helper'

module PayCalculationServices
  class ProcessWorkOrderServiceTest < ActiveSupport::TestCase
    setup do
      @work_order = work_orders(:one)
      @worker = workers(:one)
      @service = ProcessWorkOrderService.new(@work_order)
    end

    test 'should create pay calculation for work order month' do
      assert_difference 'PayCalculation.count', 1 do
        @service.call
      end
    end

    test 'should return success result' do
      result = @service.call

      assert result.success?
      assert_match /successfully/, result.value_or('')
    end

    test 'should handle errors gracefully' do
      invalid_service = ProcessWorkOrderService.new(nil)
      result = invalid_service.call

      assert result.failure?
    end
  end
end
```

### Controller Test Template

```ruby
require 'test_helper'

class WorkersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @worker = workers(:one)
    @user = users(:admin)
    sign_in @user  # If using authentication
  end

  test 'should get index' do
    get workers_url
    assert_response :success
    assert_select 'h5', 'Workers Profile'
  end

  test 'should create worker' do
    assert_difference('Worker.count') do
      post workers_url, params: {
        worker: {
          name: 'New Worker',
          worker_type: 'Full - Time',
          is_active: true
        }
      }
    end

    assert_redirected_to worker_url(Worker.last)
  end

  test 'should update worker' do
    patch worker_url(@worker), params: {
      worker: { name: 'Updated Name' }
    }

    assert_redirected_to worker_url(@worker)
    @worker.reload
    assert_equal 'Updated Name', @worker.name
  end
end
```

---

## Best Practices

### 1. Test Naming Conventions

```ruby
# ✅ Good: Descriptive, clear intent
test 'should calculate net salary from gross minus worker deductions' do
  # ...
end

# ❌ Bad: Vague, unclear
test 'calculation works' do
  # ...
end
```

### 2. Setup and Teardown

```ruby
class WorkerTest < ActiveSupport::TestCase
  def setup
    # Runs before EACH test
    @worker = Worker.create!(name: 'Test', worker_type: 'Full - Time')
  end

  def teardown
    # Runs after EACH test (usually not needed with transactions)
    # Database is automatically rolled back
  end
end
```

### 3. Use Fixtures Wisely

```yaml
# test/fixtures/workers.yml
one:
  name: John Doe
  worker_type: "Full - Time"
  is_active: true
  hired_date: <%= 1.year.ago.to_date %>

two:
  name: Jane Smith
  worker_type: "Part - Time"
  is_active: true
```

```ruby
# In your test
@worker = workers(:one)  # Loads fixture
```

### 4. Test One Thing Per Test

```ruby
# ✅ Good: Single responsibility
test 'should validate presence of name' do
  worker = Worker.new(worker_type: 'Full - Time')
  assert_not worker.valid?
  assert_includes worker.errors[:name], "can't be blank"
end

test 'should validate inclusion of worker_type' do
  worker = Worker.new(name: 'Test', worker_type: 'Invalid')
  assert_not worker.valid?
  assert_includes worker.errors[:worker_type], 'is not included in the list'
end

# ❌ Bad: Testing multiple things
test 'should validate everything' do
  worker = Worker.new
  assert_not worker.valid?
  assert worker.errors[:name].present?
  assert worker.errors[:worker_type].present?
  # Too many assertions!
end
```

### 5. Avoid Test Interdependence

```ruby
# ✅ Good: Each test is independent
test 'should create worker' do
  worker = Worker.create!(name: 'Test', worker_type: 'Full - Time')
  assert worker.persisted?
end

test 'should update worker' do
  worker = Worker.create!(name: 'Test', worker_type: 'Full - Time')
  worker.update!(name: 'Updated')
  assert_equal 'Updated', worker.name
end

# ❌ Bad: Tests depend on each other
@@shared_worker = nil

test 'A: create worker' do
  @@shared_worker = Worker.create!(name: 'Test', worker_type: 'Full - Time')
end

test 'B: update worker' do
  # Depends on test A running first!
  @@shared_worker.update!(name: 'Updated')
end
```

### 6. Test Edge Cases

```ruby
test 'should handle zero gross salary' do
  detail = PayCalculationDetail.create!(
    pay_calculation: @pay_calc,
    worker: @worker,
    gross_salary: 0.00
  )

  assert_equal(-21.25, detail.net_salary)  # Negative due to fixed deductions
end

test 'should handle nil values gracefully' do
  detail = PayCalculationDetail.new(gross_salary: nil)
  detail.calculate_net_salary

  assert_equal 0, detail.net_salary
end
```

### 7. Use Meaningful Assertions

```ruby
# ✅ Good: Specific assertions
assert_equal 5, Worker.count
assert_includes @worker.errors[:name], "can't be blank"
assert_difference 'Worker.count', 2 do
  Worker.create!(name: 'A', worker_type: 'Full - Time')
  Worker.create!(name: 'B', worker_type: 'Part - Time')
end

# Available assertions
assert value                          # value is truthy
assert_not value                      # value is falsy
assert_equal expected, actual         # ==
assert_not_equal expected, actual     # !=
assert_nil value                      # value.nil?
assert_not_nil value                  # !value.nil?
assert_includes collection, item      # collection.include?(item)
assert_instance_of Class, object      # object.instance_of?(Class)
assert_kind_of Class, object          # object.kind_of?(Class)
assert_respond_to object, :method     # object.respond_to?(:method)
assert_match /pattern/, string        # string =~ /pattern/
assert_predicate object, :method?     # object.method?
assert_raises(Exception) { code }     # code raises Exception
assert_difference 'Model.count', 1    # count increases by 1
assert_no_difference 'Model.count'    # count doesn't change
```

---

## Common Patterns

### Testing Callbacks

```ruby
test 'should apply deductions before save' do
  detail = PayCalculationDetail.new(
    pay_calculation: @pay_calc,
    worker: @worker,
    gross_salary: 5000.00
  )

  # Deductions not applied yet
  assert_nil detail.employee_deductions

  detail.save!

  # Callback triggered
  assert_not_nil detail.employee_deductions
  assert_not_nil detail.deduction_breakdown
end
```

### Testing Scopes

```ruby
test 'active scope returns only active workers' do
  active = Worker.create!(name: 'Active', worker_type: 'Full - Time', is_active: true)
  inactive = Worker.create!(name: 'Inactive', worker_type: 'Full - Time', is_active: false)

  active_workers = Worker.active

  assert_includes active_workers, active
  assert_not_includes active_workers, inactive
end
```

### Testing Dry::Monads Results

```ruby
test 'should return success result' do
  result = @service.call

  assert result.success?
  assert_match /successfully/, result.value_or('')
end

test 'should return failure result on error' do
  invalid_service = ProcessWorkOrderService.new(nil)
  result = invalid_service.call

  assert result.failure?
  assert_match /failed/i, result.failure
end
```

### Testing Database Constraints

```ruby
test 'should not allow duplicate worker per pay calculation' do
  PayCalculationDetail.create!(
    pay_calculation: @pay_calc,
    worker: @worker,
    gross_salary: 1000
  )

  # Unique constraint should prevent duplicate
  assert_raises ActiveRecord::RecordNotUnique do
    PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @worker,
      gross_salary: 2000
    )
  end
end
```

### Testing Atomic Operations

```ruby
test 'should increment gross salary atomically' do
  detail = PayCalculationDetail.create!(
    pay_calculation: @pay_calc,
    worker: @worker,
    gross_salary: 1000.00
  )

  original_salary = detail.gross_salary

  detail.increment!(:gross_salary, 500)

  assert_equal original_salary + 500, detail.gross_salary
end
```

### Testing with Transactions

```ruby
test 'should rollback on error' do
  assert_no_difference 'PayCalculation.count' do
    assert_raises ActiveRecord::RecordInvalid do
      ActiveRecord::Base.transaction do
        PayCalculation.create!(month_year: '2025-11')
        PayCalculation.create!(month_year: nil)  # Will fail validation
      end
    end
  end
end
```

---

## Troubleshooting

### Common Issues

#### 1. Fixture Errors

**Problem:** `ActiveRecord::RecordNotUnique: duplicate key`

```bash
Error: duplicate key value violates unique constraint "index_pay_calc_detail_unique_worker_per_month"
```

**Solution:** Use different fixtures or create separate records for each test

```ruby
# ❌ Bad: Reusing same fixture in multiple tests
test 'test A' do
  detail = PayCalculationDetail.create!(
    pay_calculation: pay_calculations(:january_2025),
    worker: workers(:one),
    gross_salary: 1000
  )
end

test 'test B' do
  # Fails! Same pay_calculation + worker
  detail = PayCalculationDetail.create!(
    pay_calculation: pay_calculations(:january_2025),
    worker: workers(:one),
    gross_salary: 2000
  )
end

# ✅ Good: Create unique combinations
test 'test A' do
  february = PayCalculation.create!(month_year: '2025-02')
  detail = PayCalculationDetail.create!(
    pay_calculation: february,
    worker: workers(:one),
    gross_salary: 1000
  )
end

test 'test B' do
  march = PayCalculation.create!(month_year: '2025-03')
  detail = PayCalculationDetail.create!(
    pay_calculation: march,
    worker: workers(:one),
    gross_salary: 2000
  )
end
```

#### 2. Test Pollution

**Problem:** Tests pass individually but fail when run together

```bash
# Passes
docker compose exec web rails test test/models/worker_test.rb -n test_specific

# Fails
docker compose exec web rails test test/models/worker_test.rb
```

**Solution:** Ensure tests are independent, check for shared state

```ruby
# ✅ Good: Reset state in setup/teardown
def setup
  @worker = Worker.create!(name: 'Test', worker_type: 'Full - Time')
end

# Clean up class variables if needed
def teardown
  Worker.delete_all  # Usually not needed, but sometimes required
end
```

#### 3. Slow Tests

**Problem:** Tests take too long

**Solutions:**

```ruby
# 1. Only load necessary fixtures
fixtures :workers  # Not :all

# 2. Use build instead of create when possible
test 'validation test' do
  worker = Worker.new(name: nil)  # Don't save to DB
  assert_not worker.valid?
end

# 3. Avoid unnecessary database calls
test 'scope test' do
  workers = Worker.active.to_a  # Load once
  assert workers.size > 0
  assert workers.all?(&:is_active)
end
```

#### 4. Flaky Tests

**Problem:** Tests pass/fail randomly

**Common causes:**

- Time-dependent logic (use `travel_to`)
- Random data (use fixed seeds)
- Async operations (use proper waits)

```ruby
# ✅ Good: Freeze time
test 'should use current month' do
  travel_to Time.zone.local(2025, 11, 18) do
    result = PayCalculation.find_or_create_for_month('2025-11')
    assert_not_nil result
  end
end
```

---

## Test Coverage

### Checking Coverage (Optional)

Add to Gemfile:

```ruby
group :test do
  gem 'simplecov', require: false
end
```

In `test/test_helper.rb`:

```ruby
require 'simplecov'
SimpleCov.start 'rails'
```

Run tests and check `coverage/index.html`

---

## Continuous Integration

### Running Tests in CI

```bash
# In your CI pipeline (GitHub Actions, GitLab CI, etc.)
docker compose exec -T web rails db:migrate RAILS_ENV=test
docker compose exec -T web rails test
```

### Example GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          docker compose up -d
          docker compose exec -T web rails db:migrate RAILS_ENV=test
          docker compose exec -T web rails test
```

---

## Quick Reference

### Most Used Commands

```bash
# Run all tests
docker compose exec web rails test

# Run specific test file
docker compose exec web rails test test/models/pay_calculation_test.rb

# Run specific test
docker compose exec web rails test test/models/worker_test.rb -n test_should_be_valid

# Run tests with verbose output
docker compose exec web rails test -v

# Run tests and show coverage
docker compose exec web rails test

# Run only failures from last run
docker compose exec web rails test --fail-fast
```

### Assertion Quick Reference

```ruby
# Equality
assert_equal expected, actual
assert_not_equal value1, value2

# Truthiness
assert condition
assert_not condition

# Nil checks
assert_nil value
assert_not_nil value

# Collections
assert_includes collection, item
assert_empty collection
assert_not_empty collection

# Types
assert_instance_of Class, object
assert_kind_of Class, object

# Methods
assert_respond_to object, :method_name

# Patterns
assert_match /regex/, string

# Exceptions
assert_raises(ExceptionClass) { code }
assert_nothing_raised { code }

# Database changes
assert_difference 'Model.count', 1 do
  # code that creates 1 record
end

assert_no_difference 'Model.count' do
  # code that doesn't change count
end
```

---

## Further Reading

- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Minitest Documentation](https://github.com/minitest/minitest)
- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)

---

**Happy Testing! 🎯**
