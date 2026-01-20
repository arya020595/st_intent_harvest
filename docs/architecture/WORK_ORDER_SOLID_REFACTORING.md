# WorkOrder SOLID Refactoring

## Overview

The WorkOrder model has been refactored to follow SOLID principles, making it more maintainable, testable, and extensible.

## SOLID Principles Applied

### 1. Single Responsibility Principle (SRP)

**Problem**: The WorkOrder model was handling multiple responsibilities:

- Business logic
- Type-specific validations
- Type checking
- Association requirements

**Solution**: Separated concerns into focused components:

#### `WorkOrderTypeValidator` (app/validators/work_order_type_validator.rb)

- **Single Responsibility**: Validates fields based on work_order_rate_type
- Handles type-specific validation logic
- Easy to test in isolation
- Clear validation rules per type

```ruby
# Validates:
# - normal type: requires start_date, block_id
# - work_days type: requires work_month
# - resources type: no additional field validations
```

#### `WorkOrderTypeBehavior` (app/models/concerns/work_order_type_behavior.rb)

- **Single Responsibility**: Manages type-specific behavior
- Type checking methods (normal_type?, work_days_type?, resources_type?)
- Association requirements logic
- Strategy pattern for different type requirements

#### `WorkOrder` Model

- **Reduced Responsibility**: Focus on core domain logic
- AASM state machine
- Denormalization
- Associations and history tracking

---

### 2. Open/Closed Principle (OCP)

**Open for extension, closed for modification**

#### Adding New Work Order Types

To add a new type (e.g., 'maintenance'):

1. **Update WorkOrderRate enum** (no changes to WorkOrder needed):

```ruby
enum :work_order_rate_type, {
  normal: 'normal',
  resources: 'resources',
  work_days: 'work_days',
  maintenance: 'maintenance'  # NEW TYPE
}
```

2. **Extend WorkOrderTypeValidator**:

```ruby
def validate_by_type(record)
  case record.work_order_rate.work_order_rate_type
  when 'normal'
    validate_normal_type(record)
  when 'work_days'
    validate_work_days_type(record)
  when 'resources'
    validate_resources_type(record)
  when 'maintenance'
    validate_maintenance_type(record)  # NEW
  end
end

def validate_maintenance_type(record)
  # Add new validation rules
end
```

3. **Extend WorkOrderTypeBehavior**:

```ruby
def required_associations
  case work_order_rate&.work_order_rate_type
  when 'normal'
    [:workers_or_items]
  when 'work_days'
    [:workers]
  when 'resources'
    [:items]
  when 'maintenance'
    [:workers, :items]  # NEW - requires both
  else
    []
  end
end
```

**No changes needed in the WorkOrder model!**

---

### 3. Liskov Substitution Principle (LSP)

**Objects should be replaceable with instances of their subtypes**

- The concern `WorkOrderTypeBehavior` can be included in any model that has a `work_order_rate` association
- Methods return consistent types (booleans for type checks, arrays for requirements)
- No unexpected behavior when switching between types

---

### 4. Interface Segregation Principle (ISP)

**Clients shouldn't depend on interfaces they don't use**

#### Separated Interfaces:

- **Type Checking**: `normal_type?`, `work_days_type?`, `resources_type?`
- **Validation**: `WorkOrderTypeValidator` (only used during validation)
- **Guard Logic**: `has_required_associations?` (only used for AASM guards)

Each interface serves a specific purpose and can be used independently.

---

### 5. Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions**

#### Before (Concrete Dependencies):

```ruby
def workers_or_items?
  workers_count = work_order_workers.reject(&:marked_for_destruction?).count
  items_count = work_order_items.reject(&:marked_for_destruction?).count

  return workers_count.positive? if work_days_type?
  return items_count.positive? if resources_type?
  workers_count.positive? || items_count.positive?
end
```

#### After (Abstract Dependencies):

```ruby
# WorkOrder model - depends on abstract interface
def workers_or_items?
  has_required_associations?
end

# Concern - provides abstract interface
def has_required_associations?
  requirements = required_associations  # Strategy pattern
  # Implementation details hidden
end
```

The `workers_or_items?` method now depends on the abstract `has_required_associations?` interface, not the concrete implementation details.

---

## Benefits of Refactoring

### 1. **Maintainability**

- Clear separation of concerns
- Each file has a single, well-defined purpose
- Easy to locate and fix bugs

### 2. **Testability**

- Validator can be tested independently
- Concern can be tested in isolation
- Mock dependencies easily

### 3. **Extensibility**

- Add new work order types without modifying existing code
- Extend behavior through composition
- Strategy pattern allows flexible requirements

### 4. **Readability**

- WorkOrder model is now ~60 lines shorter
- Clear, self-documenting code
- Type-specific logic is isolated

### 5. **Reusability**

- `WorkOrderTypeBehavior` can be included in other models if needed
- Validator logic can be shared or extended
- DRY principle followed

---

## File Structure

```
app/
├── models/
│   ├── work_order.rb                      # Core domain model (clean & focused)
│   └── concerns/
│       └── work_order_type_behavior.rb    # Type-specific behavior
└── validators/
    └── work_order_type_validator.rb       # Type-specific validations
```

---

## Validation Rules by Type

| Type      | start_date  | block_id    | work_month  | workers     | items       | workers OR items |
| --------- | ----------- | ----------- | ----------- | ----------- | ----------- | ---------------- |
| normal    | ✅ Required | ✅ Required | ❌ Not req. | ❌          | ❌          | ✅ Required      |
| work_days | ❌ Not req. | ❌ Not req. | ✅ Required | ✅ Required | ❌          | ❌               |
| resources | ❌ Not req. | ❌ Not req. | ❌ Not req. | ❌          | ✅ Required | ❌               |

---

## Testing Strategy

### Unit Tests for Validator:

```ruby
# test/validators/work_order_type_validator_test.rb
test "normal type requires start_date and block_id"
test "work_days type requires work_month"
test "resources type has no field requirements"
```

### Unit Tests for Concern:

```ruby
# test/models/concerns/work_order_type_behavior_test.rb
test "normal_type? returns true for normal work orders"
test "required_associations returns correct requirements per type"
test "has_required_associations? validates workers for work_days"
```

### Integration Tests for Model:

```ruby
# test/models/work_order_test.rb
test "valid normal type work order"
test "valid work_days type work order"
test "valid resources type work order"
test "invalid work orders fail validation appropriately"
```

---

## Migration Path

If you need to add validations in the future:

1. **Field validations** → Add to `WorkOrderTypeValidator`
2. **Association requirements** → Update `required_associations` in concern
3. **Type checking** → Add helper methods to concern
4. **Business logic** → Add to WorkOrder model

This keeps responsibilities clear and maintains SOLID principles.
