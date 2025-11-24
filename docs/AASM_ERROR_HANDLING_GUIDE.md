# AASM Error Handling Guide

## Overview

This guide explains the AASM error handling system implemented for work orders, which provides user-friendly error messages when state transitions fail.

## Architecture

The system consists of two main components:

1. **WorkOrderGuardMessages** - Error message generation for guard failures
2. **AasmErrorHandler** - Reusable error handling logic for AASM transitions

---

## WorkOrderGuardMessages Concern

### Location

`app/models/concerns/work_order_guard_messages.rb`

### Purpose

Generates user-friendly error messages when AASM guard methods fail (e.g., when trying to submit a work order without required workers or items).

### How It Works

#### 1. Message Templates

The concern defines error messages as constants:

```ruby
GUARD_FAILURE_MESSAGES = {
  workers: 'Cannot submit work order: Please add at least one worker before submitting.',
  items: 'Cannot submit work order: Please add at least one item/resource before submitting.',
  workers_or_items: 'Cannot submit work order: Please add at least one worker or item before submitting.',
  default: 'Cannot submit work order: Required information is missing.'
}.freeze
```

#### 2. Dynamic Message Selection

The `guard_failure_message` method automatically selects the appropriate message based on the work order type:

```ruby
def guard_failure_message
  requirement_type = required_associations.first || :default
  GUARD_FAILURE_MESSAGES[requirement_type] || GUARD_FAILURE_MESSAGES[:default]
end
```

### Usage

#### Include in Model

```ruby
class WorkOrder < ApplicationRecord
  include WorkOrderGuardMessages
  # ... other code
end
```

#### Call the Method

```ruby
work_order = WorkOrder.new
work_order.guard_failure_message
# => "Cannot submit work order: Please add at least one worker or item before submitting."
```

### Logic Flow

```
Work Order Type → Required Associations → Message Selection
├── Normal        → :workers_or_items    → "add at least one worker or item"
├── Work Days     → :workers             → "add at least one worker"
├── Resources     → :items               → "add at least one item/resource"
└── Unknown       → :default             → "Required information is missing"
```

### Extending for New Types

To add a new work order type:

1. Add the message to `GUARD_FAILURE_MESSAGES`:

```ruby
GUARD_FAILURE_MESSAGES = {
  # ... existing messages
  new_type: 'Cannot submit work order: Please add new type requirements.',
}.freeze
```

2. Update `WorkOrderTypeBehavior` concern to return the new requirement type:

```ruby
def required_associations
  case work_order_rate&.work_order_rate_type
  when 'new_type'
    [:new_type]
  # ... existing cases
  end
end
```

---

## AasmErrorHandler Module

### Location

`app/services/concerns/aasm_error_handler.rb`

### Purpose

Provides reusable logic for handling AASM::InvalidTransition errors with user-friendly messages and structured logging.

### Key Methods

#### 1. `handle_aasm_error(error, model, context:)`

**Purpose:** Main error handler that transforms AASM errors into user-friendly messages.

**Parameters:**

- `error` - The `AASM::InvalidTransition` exception
- `model` - The ActiveRecord model that failed transition
- `context` - (Optional) Context for logging, defaults to `self.class.name`

**Returns:** User-friendly error message string

**Logic:**

```ruby
def handle_aasm_error(error, model, context: self.class.name)
  log_aasm_error(error, model, context)

  if guard_callback_failed?(error)
    model.respond_to?(:guard_failure_message) ? model.guard_failure_message : default_guard_message
  else
    "Cannot transition work order: #{error.message}"
  end
end
```

**Flow:**

1. Log the error with structured data
2. Check if error is due to guard failure
3. If guard failed: Use model's custom message (if available) or default
4. If other error: Return generic transition error message

#### 2. `guard_callback_failed?(error)`

**Purpose:** Detects if the error was caused by a failed guard callback.

**Parameters:**

- `error` - The `AASM::InvalidTransition` exception

**Returns:** `true` if guard failed, `false` otherwise

**Implementation:**

```ruby
def guard_callback_failed?(error)
  error.message.include?('Failed callback(s)')
end
```

#### 3. `log_aasm_error(error, model, context)`

**Purpose:** Logs AASM transition errors with structured data using AppLogger.

**Parameters:**

- `error` - The AASM exception
- `model` - The model that failed
- `context` - Logging context (class name)

**Implementation:**

```ruby
def log_aasm_error(error, model, context)
  AppLogger.error(
    'AASM transition failed',
    context: context,
    error_class: error.class.name,
    error_message: error.message,
    model_id: model.id,
    from_state: model.aasm.current_state
  )
end
```

**Log Output Example:**

```
[ERROR] AASM transition failed
  context: WorkOrderServices::CreateService
  error_class: AASM::InvalidTransition
  error_message: Event 'mark_complete' cannot transition from 'ongoing'. Failed callback(s): [:workers_or_items?]
  model_id: 123
  from_state: ongoing
```

#### 4. `default_guard_message`

**Purpose:** Provides fallback message when model doesn't implement `guard_failure_message`.

**Returns:** Default error message string

**Implementation:**

```ruby
def default_guard_message
  'Cannot complete this action: Required conditions are not met.'
end
```

### Usage

#### Include in Service

```ruby
module WorkOrderServices
  class MarkCompleteService
    include Dry::Monads[:result]
    include AasmErrorHandler

    def call
      work_order.mark_complete!
      Success("Work order submitted")
    rescue AASM::InvalidTransition => e
      error_message = handle_aasm_error(e, work_order)
      Failure(error_message)
    end
  end
end
```

#### Complete Example

```ruby
module MyServices
  class MyService
    include Dry::Monads[:result]
    include AasmErrorHandler

    def initialize(model)
      @model = model
    end

    def call
      perform_transition
    end

    private

    def perform_transition
      @model.some_event!
      Success("Transition successful")
    rescue AASM::InvalidTransition => e
      # Automatically handles guard failures and other AASM errors
      error_message = handle_aasm_error(e, @model)
      Failure(error_message)
    rescue StandardError => e
      # Handle other errors
      AppLogger.error('Service failed', context: self.class.name, error: e.message)
      Failure("Operation failed: #{e.message}")
    end
  end
end
```

---

## Integration Example

### Complete Flow: WorkOrder Submission

#### 1. Model Definition

```ruby
class WorkOrder < ApplicationRecord
  include AASM
  include WorkOrderGuardMessages

  aasm column: :work_order_status do
    state :ongoing, initial: true
    state :pending

    event :mark_complete do
      transitions from: :ongoing, to: :pending, guard: :workers_or_items?
    end
  end

  def workers_or_items?
    has_required_associations?
  end
end
```

#### 2. Service Implementation

```ruby
module WorkOrderServices
  class MarkCompleteService
    include Dry::Monads[:result]
    include AasmErrorHandler

    def initialize(work_order, remarks = nil)
      @work_order = work_order
      @remarks = remarks
    end

    def call
      execute_transition
    end

    private

    def execute_transition
      @work_order.mark_complete!(remarks: @remarks)
      Success("Work order has been submitted for approval.")
    rescue AASM::InvalidTransition => e
      error_message = handle_aasm_error(e, @work_order)
      Failure(error_message)
    rescue StandardError => e
      AppLogger.error('WorkOrder submission failed',
                      context: self.class.name,
                      error: e.message)
      Failure("Failed to mark work order as complete: #{e.message}")
    end
  end
end
```

#### 3. Controller Usage

```ruby
class WorkOrdersController < ApplicationController
  include ResponseHandling

  def mark_complete
    result = WorkOrderServices::MarkCompleteService.new(@work_order, remarks).call
    handle_result(result,
                  success_path: work_order_path(@work_order),
                  error_path: work_order_path(@work_order))
  end
end
```

#### 4. User Experience

**Scenario A: Guard Failure (No Workers)**

```
User Action: Submits work order without adding workers
System Response: "Cannot submit work order: Please add at least one worker before submitting."
Log Output: [ERROR] AASM transition failed (with full context)
```

**Scenario B: Invalid State Transition**

```
User Action: Tries to submit already-submitted work order
System Response: "Cannot transition work order: Event 'mark_complete' cannot transition from 'pending'"
Log Output: [ERROR] AASM transition failed (with full context)
```

**Scenario C: Success**

```
User Action: Submits valid work order with workers
System Response: "Work order has been submitted for approval."
Log Output: [INFO] Work order transitioned to pending
```

---

## Error Message Decision Tree

```
AASM::InvalidTransition Raised
│
├─ Is it a guard failure? (Failed callback(s))
│  ├─ YES
│  │  ├─ Does model have guard_failure_message method?
│  │  │  ├─ YES → Return model's custom message
│  │  │  └─ NO  → Return default_guard_message
│  │
│  └─ NO
│     └─ Return generic transition error with AASM message
│
└─ Logged with structured data via AppLogger
```

---

## Testing Guidelines

### Unit Tests for WorkOrderGuardMessages

```ruby
RSpec.describe WorkOrderGuardMessages do
  describe '#guard_failure_message' do
    context 'when work order type is normal' do
      it 'returns workers_or_items message' do
        work_order = build(:work_order, :normal_type)
        expect(work_order.guard_failure_message)
          .to include('worker or item')
      end
    end

    context 'when work order type is work_days' do
      it 'returns workers message' do
        work_order = build(:work_order, :work_days_type)
        expect(work_order.guard_failure_message)
          .to include('at least one worker')
      end
    end

    context 'when work order type is resources' do
      it 'returns items message' do
        work_order = build(:work_order, :resources_type)
        expect(work_order.guard_failure_message)
          .to include('item/resource')
      end
    end
  end
end
```

### Unit Tests for AasmErrorHandler

```ruby
RSpec.describe AasmErrorHandler do
  let(:service_class) do
    Class.new do
      include Dry::Monads[:result]
      include AasmErrorHandler

      def test_handle(error, model)
        handle_aasm_error(error, model)
      end
    end
  end

  let(:service) { service_class.new }
  let(:work_order) { create(:work_order) }

  describe '#handle_aasm_error' do
    context 'when guard callback fails' do
      let(:error) do
        AASM::InvalidTransition.new(
          "Event 'mark_complete' cannot transition from 'ongoing'. Failed callback(s): [:workers_or_items?]"
        )
      end

      it 'returns custom guard failure message' do
        expect(service.send(:test_handle, error, work_order))
          .to eq(work_order.guard_failure_message)
      end

      it 'logs the error' do
        expect(AppLogger).to receive(:error)
        service.send(:test_handle, error, work_order)
      end
    end

    context 'when transition is invalid for other reasons' do
      let(:error) do
        AASM::InvalidTransition.new(
          "Event 'mark_complete' cannot transition from 'pending'"
        )
      end

      it 'returns generic transition error' do
        expect(service.send(:test_handle, error, work_order))
          .to include('Cannot transition work order')
      end
    end
  end
end
```

### Integration Tests

```ruby
RSpec.describe WorkOrderServices::MarkCompleteService do
  describe '#call' do
    context 'when work order has no workers or items' do
      let(:work_order) { create(:work_order, :without_workers_or_items) }
      let(:service) { described_class.new(work_order) }

      it 'returns user-friendly failure message' do
        result = service.call

        expect(result).to be_failure
        expect(result.failure).to include('Please add at least one')
      end

      it 'logs the error with AppLogger' do
        expect(AppLogger).to receive(:error).with(
          'AASM transition failed',
          hash_including(
            context: 'WorkOrderServices::MarkCompleteService',
            error_class: 'AASM::InvalidTransition'
          )
        )

        service.call
      end
    end
  end
end
```

---

## Best Practices

### 1. Always Include AasmErrorHandler in Services

```ruby
# ✅ Good
class MyService
  include Dry::Monads[:result]
  include AasmErrorHandler

  def call
    model.transition!
  rescue AASM::InvalidTransition => e
    error_message = handle_aasm_error(e, model)
    Failure(error_message)
  end
end

# ❌ Bad - duplicating error handling logic
class MyService
  def call
    model.transition!
  rescue AASM::InvalidTransition => e
    if e.message.include?('Failed callback')
      Failure(model.guard_failure_message)
    else
      Failure("Error: #{e.message}")
    end
  end
end
```

### 2. Use Structured Logging

```ruby
# ✅ Good - handled automatically by AasmErrorHandler
error_message = handle_aasm_error(e, work_order)

# ❌ Bad - unstructured logging
Rails.logger.error("Error: #{e.message}")
```

### 3. Provide Context-Specific Messages

```ruby
# ✅ Good - specific to work order type
GUARD_FAILURE_MESSAGES = {
  workers: 'Please add at least one worker before submitting.',
  # ...
}

# ❌ Bad - generic message
"Validation failed"
```

### 4. Keep Error Messages User-Friendly

```ruby
# ✅ Good
"Cannot submit work order: Please add at least one worker before submitting."

# ❌ Bad - technical jargon
"Event 'mark_complete' cannot transition from 'ongoing'. Failed callback(s): [:workers_or_items?]"
```

---

## Troubleshooting

### Error: "undefined method `guard_failure_message'"

**Cause:** Model doesn't include `WorkOrderGuardMessages`

**Solution:**

```ruby
class MyModel < ApplicationRecord
  include WorkOrderGuardMessages  # Add this
  # ...
end
```

### Error: "uninitialized constant AasmErrorHandler"

**Cause:** Concern file not loaded or incorrect location

**Solution:** Ensure file is in `app/services/concerns/aasm_error_handler.rb`

### Messages Not Appearing Correctly

**Cause:** `required_associations` method not returning correct symbol

**Solution:** Check `WorkOrderTypeBehavior` concern implementation:

```ruby
def required_associations
  case work_order_rate&.work_order_rate_type
  when 'normal'
    [:workers_or_items]  # This symbol must match GUARD_FAILURE_MESSAGES keys
  # ...
  end
end
```

---

## Summary

### WorkOrderGuardMessages

- **Purpose:** Generate user-friendly error messages for guard failures
- **Location:** `app/models/concerns/work_order_guard_messages.rb`
- **Key Method:** `guard_failure_message`
- **Usage:** Include in models with AASM guards

### AasmErrorHandler

- **Purpose:** Reusable AASM error handling with logging
- **Location:** `app/services/concerns/aasm_error_handler.rb`
- **Key Method:** `handle_aasm_error(error, model, context:)`
- **Usage:** Include in services that perform AASM transitions

### Benefits

✅ User-friendly error messages  
✅ Consistent error handling across services  
✅ Structured logging with AppLogger  
✅ DRY - no code duplication  
✅ SOLID principles compliance  
✅ Easy to test and maintain  
✅ Easy to extend for new types

---

## Related Documentation

- [GUARD_FAILURE_REFACTORING.md](./GUARD_FAILURE_REFACTORING.md) - Complete refactoring details
- [WORK_ORDER_STATUS_FLOW.md](./WORK_ORDER_STATUS_FLOW.md) - Work order state machine
- [APP_LOGGER_GUIDE.md](./APP_LOGGER_GUIDE.md) - AppLogger usage guide
