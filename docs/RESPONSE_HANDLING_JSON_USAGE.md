# ResponseHandling Concern - JSON Response Usage

## Overview

The `ResponseHandling` concern now fully supports JSON responses with redirect URLs, making it perfect for AJAX requests and JavaScript-based navigation.

## JSON Response Format

### Success Response (with redirect)

```json
{
  "success": true,
  "message": "Work order was successfully approved.",
  "redirect_url": "/work_order/approvals"
}
```

### Error Response (with redirect)

```json
{
  "success": false,
  "error": "Work order cannot be approved in current state.",
  "redirect_url": "/work_order/approvals/123"
}
```

### Error Response (form validation - no redirect)

```json
{
  "success": false,
  "error": "Title can't be blank, Start date is required"
}
```

## JavaScript Usage Examples

### Example 1: Stimulus Controller with Turbo

```javascript
// app/javascript/controllers/approval_modal_controller.js
async sendRequest(action, formData) {
  try {
    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        action: action,
        work_order_history: { remarks: formData.get('remarks') }
      })
    });

    const data = await response.json();

    if (data.success) {
      // Redirect using Turbo
      Turbo.visit(data.redirect_url);

      // Or use window.location for full page reload
      // window.location.href = data.redirect_url;
    } else {
      // Show error message
      this.showError(data.error);
    }
  } catch (error) {
    console.error('Request failed:', error);
  }
}
```

### Example 2: Plain JavaScript with Fetch

```javascript
async function approveWorkOrder(workOrderId) {
  const response = await fetch(`/work_order/approvals/${workOrderId}/approve`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
    },
  });

  const data = await response.json();

  if (data.success) {
    // Show success message
    alert(data.message);

    // Redirect to the provided URL
    window.location.href = data.redirect_url;
  } else {
    // Show error message
    alert(data.error);

    // Optionally redirect to error URL if provided
    if (data.redirect_url) {
      window.location.href = data.redirect_url;
    }
  }
}
```

### Example 3: jQuery AJAX

```javascript
$.ajax({
  url: "/work_order/approvals/123/approve",
  method: "POST",
  dataType: "json",
  headers: {
    "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
  },
  success: function (data) {
    if (data.success) {
      // Show success notification
      showNotification(data.message, "success");

      // Redirect after a short delay
      setTimeout(function () {
        window.location.href = data.redirect_url;
      }, 1000);
    }
  },
  error: function (xhr) {
    const data = xhr.responseJSON;
    showNotification(data.error, "error");

    if (data.redirect_url) {
      setTimeout(function () {
        window.location.href = data.redirect_url;
      }, 2000);
    }
  },
});
```

## Controller Usage

The `ResponseHandling` concern automatically handles both HTML and JSON responses based on the `Accept` header.

### Basic Usage

```ruby
def approve
  service = WorkOrderServices::ApproveService.new(@work_order, current_user)
  result = service.call

  handle_result(result,
                success_path: work_order_approvals_path,
                error_path: work_order_approval_path(@work_order))
end
```

### Different Paths for HTML vs JSON

```ruby
def request_amendment
  service = WorkOrderServices::RequestAmendmentService.new(@work_order, remarks)
  result = service.call

  handle_result(result,
                success_path: work_order_approvals_path,        # HTML redirects to index
                json_success_path: work_order_approval_path(@work_order),  # JSON stays on show
                error_path: work_order_approval_path(@work_order))
end
```

### Dynamic Path with Lambda (for create actions)

```ruby
def create
  service = WorkOrderServices::CreateService.new(work_order_params)
  result = service.call(draft: params[:draft].present?)

  handle_result(result,
                success_path: ->(data) { work_order_detail_path(data[:work_order]) },
                error_action: :new)
end
```

### Render Template on Error

```ruby
def update
  service = WorkOrderServices::UpdateService.new(@work_order, work_order_params)
  result = service.call(submit: params[:submit].present?)

  handle_result(result,
                success_path: work_order_detail_path(@work_order),
                error_action: :edit)  # Renders :edit template instead of redirecting
end
```

## Testing JSON Responses

### Using curl

```bash
# Test success case
curl -X POST http://localhost:3000/work_order/approvals/123/approve \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: your-token-here"

# Test error case
curl -X POST http://localhost:3000/work_order/approvals/123/request_amendment \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: your-token-here" \
  -d '{"work_order_history": {"remarks": ""}}'
```

### Using Rails console

```ruby
# Create a test request
app.post work_order_approval_approve_path(123),
  headers: { 'Accept' => 'application/json' }

# Check response
JSON.parse(response.body)
# => {"success"=>true, "message"=>"...", "redirect_url"=>"/work_order/approvals"}
```

## Benefits

1. **Unified Response Format**: Consistent JSON structure across all actions
2. **JavaScript-Friendly**: Includes redirect URLs for client-side navigation
3. **Graceful Degradation**: HTML requests work normally with redirects
4. **Turbo Compatible**: Works seamlessly with Turbo Drive navigation
5. **Error Handling**: Distinguishes between redirectable errors and form validation errors
6. **Success Indicator**: Boolean `success` field for easy conditional logic

## Best Practices

1. Always check the `success` field before handling the response
2. Use `redirect_url` for navigation to maintain consistent routing
3. Display `message` or `error` to provide user feedback
4. Handle network errors separately from application errors
5. Consider using Turbo.visit() for smoother page transitions

## Service Layer Integration

Services should return properly structured results:

**Simple message:**

```ruby
Success('Work order was approved successfully.')
Failure('Cannot approve work order.')
```

**Hash with data (for create actions):**

```ruby
Success(work_order: work_order, message: 'Work order was created.')
Failure(work_order.errors.full_messages)
```

The concern automatically extracts the message and passes data to lambda paths.

## Migration Guide

**Before (manual response handling):**

```ruby
result.either(
  ->(message) {
    respond_to do |format|
      format.html { redirect_to approvals_path, notice: message }
      format.json { render json: { message: message } }
    end
  },
  ->(error) {
    respond_to do |format|
      format.html { redirect_to approval_path(@work_order), alert: error }
      format.json { render json: { error: error }, status: :unprocessable_entity }
    end
  }
)
```

**After (using concern):**

```ruby
handle_result(result, success_path: approvals_path, error_path: approval_path(@work_order))
```

Much cleaner with automatic JSON support and redirect URLs!
