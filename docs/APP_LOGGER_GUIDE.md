# AppLogger Guide

This guide explains how to use the AppLogger universal logging service.

## Overview

**AppLogger** is a single, universal logging service that can be used anywhere in your Rails application:

- Models
- Services
- Jobs
- Controllers
- Any Ruby class

**No includes needed** - just call `AppLogger` directly!

## Key Features

- **Universal**: One logger for all components
- **Simple**: No concerns, no includes, no mixins
- **Structured**: Consistent log format with context
- **Contextual**: Automatically includes user_id from Current.user
- **Environment-aware**: JSON in production, readable in development
- **Service helpers**: Built-in methods for service operation logging

## Basic Usage

### Simple Logging

```ruby
# In any class - just call AppLogger directly
AppLogger.info('User logged in', context: 'AuthController', user_id: user.id)
AppLogger.warn('Invalid token', context: 'TokenValidator', token: token[0..5])
AppLogger.error('Payment failed', context: 'PaymentService', error: e.message)
AppLogger.debug('Cache hit', context: 'CacheService', key: cache_key)
```

### Service Operation Logging

For service objects, use the specialized service methods:

```ruby
AppLogger.service_start('CreateWorkOrder', context: self.class.name, params: params)
AppLogger.service_success('CreateWorkOrder', context: self.class.name, work_order_id: work_order.id)
AppLogger.service_failure('CreateWorkOrder', context: self.class.name, error: e)
```

## Complete Examples

### In a Model

```ruby
class WorkOrder < ApplicationRecord
  after_create :log_creation
  after_update :log_update

  def submit!
    AppLogger.info('Submitting work order', context: self.class.name, work_order_id: id)
    update!(status: 'submitted')
    AppLogger.info('Work order submitted', context: self.class.name, work_order_id: id)
  rescue StandardError => e
    AppLogger.error('Submission failed', context: self.class.name, work_order_id: id, error: e.message)
    raise
  end

  private

  def log_creation
    AppLogger.info('Work order created', context: self.class.name, work_order_id: id)
  end

  def log_update
    if saved_change_to_status?
      AppLogger.info('Status changed',
                     context: self.class.name,
                     work_order_id: id,
                     from: status_before_last_save,
                     to: status)
    end
  end
end
```

### In a Service

```ruby
class WorkOrderServices::CreateService
  include Dry::Monads[:result]

  def initialize(params)
    @params = params
  end

  def call
    AppLogger.service_start('CreateWorkOrder', context: self.class.name, params: @params)

    work_order = WorkOrder.new(@params)

    if work_order.save
      AppLogger.service_success('CreateWorkOrder', context: self.class.name, work_order_id: work_order.id)
      Success(work_order)
    else
      AppLogger.service_failure('CreateWorkOrder',
                                context: self.class.name,
                                error: work_order.errors.full_messages.join(', '))
      Failure(work_order.errors)
    end
  rescue StandardError => e
    AppLogger.service_failure('CreateWorkOrder', context: self.class.name, error: e)
    Failure(e.message)
  end
end
```

### In a Job

```ruby
class ProcessWorkOrderJob < ApplicationJob
  def perform(work_order_id)
    AppLogger.info('Job started', context: self.class.name, work_order_id: work_order_id)

    work_order = WorkOrder.find(work_order_id)
    work_order.process!

    AppLogger.info('Job completed', context: self.class.name, work_order_id: work_order_id)
  rescue StandardError => e
    AppLogger.error('Job failed', context: self.class.name, error: e.message)
    raise
  end
end
```

### In a Controller

```ruby
class WorkOrdersController < ApplicationController
  def create
    AppLogger.info('Creating work order', context: self.class.name, params: work_order_params)

    result = WorkOrderServices::CreateService.new(work_order_params).call

    if result.success?
      AppLogger.info('Work order created', context: self.class.name, work_order_id: result.value!.id)
      redirect_to work_order_path(result.value!)
    else
      AppLogger.warn('Creation failed', context: self.class.name, errors: result.failure.full_messages)
      render :new
    end
  end
end
```

## Available Methods

### Basic Logging

- `AppLogger.info(message, context:, **data)` - Normal operations
- `AppLogger.warn(message, context:, **data)` - Warnings, validation failures
- `AppLogger.error(message, context:, **data)` - Errors, exceptions
- `AppLogger.debug(message, context:, **data)` - Debug information

### Service Logging

- `AppLogger.service_start(operation, context:, **data)` - Log service start
- `AppLogger.service_success(operation, context:, **data)` - Log service success
- `AppLogger.service_failure(operation, context:, error:, **data)` - Log service failure

## Best Practices

1. **Always include context**: Pass `context: self.class.name` for automatic class tracking

   ```ruby
   AppLogger.info('Operation started', context: self.class.name, user_id: user.id)
   ```

2. **Use appropriate log levels**:

   - `info`: Normal operations, state changes
   - `warn`: Recoverable issues, validation failures
   - `error`: Exceptions, critical failures
   - `debug`: Detailed debugging information

3. **Log service boundaries**: Use service_start/success/failure for service operations

   ```ruby
   AppLogger.service_start('ProcessPayment', context: self.class.name, amount: amount)
   # ... operation ...
   AppLogger.service_success('ProcessPayment', context: self.class.name, transaction_id: tx.id)
   ```

4. **Include relevant data**: Add IDs and important context

   ```ruby
   AppLogger.info('Status changed',
                  context: self.class.name,
                  work_order_id: id,
                  from: old_status,
                  to: new_status)
   ```

5. **Error logging**: Pass exception objects or error messages

   ```ruby
   rescue StandardError => e
     AppLogger.service_failure('Operation', context: self.class.name, error: e)
   end
   ```

## Automatic Features

- **User tracking**: Automatically includes `Current.user.id` if available
- **Timestamp**: ISO8601 timestamp on all logs
- **Parameter sanitization**: Removes password, token, secret, api_key
- **Error backtraces**: First 5 lines included for Exception objects
- **Environment formatting**: JSON in production, readable in development

## Migration from Rails.logger

**Before:**

```ruby
Rails.logger.info "Creating work order for user #{user_id}"
Rails.logger.error "Failed: #{e.message}"
```

**After:**

```ruby
AppLogger.info('Creating work order', context: self.class.name, user_id: user_id)
AppLogger.error('Operation failed', context: self.class.name, error: e.message)
```

## Log Output Examples

### Development (Human-Readable)

```
[WorkOrderServices::CreateService] Service started: CreateWorkOrder | user_id= | draft=false | work_order_rate_type=normal
[WorkOrderServices::CreateService] Service completed successfully: CreateWorkOrder | user_id= | work_order_id=789 | status=pending
[WorkOrder] Work order created | user_id= | work_order_id=789
```

### Production (JSON)

```json
{
  "message": "Service started: CreateWorkOrder",
  "context": "WorkOrderServices::CreateService",
  "user_id": null,
  "timestamp": "2025-11-17T06:24:09Z",
  "draft": false,
  "work_order_rate_type": "normal"
}
```

## Implementation Details

**Location**: `app/services/app_logger.rb`

The AppLogger is implemented as a class with class methods (singleton pattern), making it available globally without any setup. It follows SOLID principles:

- **Single Responsibility**: Only handles logging
- **Open/Closed**: Easy to extend with new log methods
- **Dependency Inversion**: Depends on Rails.logger abstraction
