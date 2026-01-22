# AppLogger Quick Start

## TL;DR

One logger for everything. No includes needed. Just call `AppLogger`.

## Usage

```ruby
# Anywhere in your code
AppLogger.info('What happened', context: self.class.name, data: value)
AppLogger.warn('Warning message', context: self.class.name, reason: 'xyz')
AppLogger.error('Error occurred', context: self.class.name, error: e.message)
```

## Service Operations

```ruby
AppLogger.service_start('OperationName', context: self.class.name, params: params)
AppLogger.service_success('OperationName', context: self.class.name, result: result)
AppLogger.service_failure('OperationName', context: self.class.name, error: error)
```

## Real Examples

### Model

```ruby
class WorkOrder < ApplicationRecord
  after_create do
    AppLogger.info('Work order created', context: self.class.name, work_order_id: id)
  end
end
```

### Service

```ruby
class WorkOrderServices::CreateService
  def call
    AppLogger.service_start('CreateWorkOrder', context: self.class.name, params: @params)
    # ... your code ...
    AppLogger.service_success('CreateWorkOrder', context: self.class.name, work_order_id: work_order.id)
  end
end
```

### Job

```ruby
class ProcessWorkOrderJob < ApplicationJob
  def perform(work_order_id)
    AppLogger.info('Processing', context: self.class.name, work_order_id: work_order_id)
    # ... your code ...
  end
end
```

### Controller

```ruby
class WorkOrdersController < ApplicationController
  def create
    AppLogger.info('Creating work order', context: self.class.name)
    # ... your code ...
  end
end
```

## Output

**Development:**

```
[WorkOrderServices::CreateService] Service started: CreateWorkOrder | user_id=123 | params={...}
```

**Production:**

```json
{
  "message": "Service started: CreateWorkOrder",
  "context": "WorkOrderServices::CreateService",
  "user_id": 123,
  "timestamp": "2025-11-17T06:24:09Z"
}
```

## That's It!

See [APP_LOGGER_GUIDE.md](APP_LOGGER_GUIDE.md) for full documentation.
