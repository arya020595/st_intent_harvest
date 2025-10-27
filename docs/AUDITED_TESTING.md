# Testing Audited Gem

## What is Audited?

Audited is an ORM extension that automatically tracks changes to your ActiveRecord models. It creates an audit trail of who changed what and when.

## How to Test Audited

### 1. Console Testing

```bash
docker compose exec web rails console
```

```ruby
# Enable auditing (if it was disabled)
Audited.auditing_enabled = true

# Set current user (important for tracking who made changes)
Current.user = User.find_by(email: 'conductor@example.com')

# Test 1: Update a record
wo = WorkOrder.first
wo.update!(work_order_status: 'pending')

# View the audit trail
wo.audits.last
# => Shows: action, user_id, audited_changes, created_at

# Test 2: View all changes
wo.audits.each do |audit|
  puts "#{audit.action} by User ##{audit.user_id} at #{audit.created_at}"
  puts "Changes: #{audit.audited_changes.inspect}"
end

# Test 3: See who made changes
Audited::Audit.where(auditable_type: 'WorkOrder').each do |audit|
  puts "Work Order ##{audit.auditable_id} #{audit.action} by User ##{audit.user_id}"
end
```

### 2. Using the Test Script

Run the provided test script:

```bash
docker compose exec web rails runner tmp/test_audited.rb
```

### 3. In Controllers

Audited automatically works in controllers when you have authentication set up:

```ruby
class WorkOrder::DetailsController < ApplicationController
  before_action :set_current_user

  def update
    @work_order = WorkOrder.find(params[:id])
    authorize [:work_order, :detail], @work_order

    if @work_order.update(work_order_params)
      # Audit is automatically created!
      # It will include Current.user if set
      redirect_to [:work_order, :detail, @work_order]
    else
      render :edit
    end
  end

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

## What Gets Tracked?

For `WorkOrder` model (which has `audited` line):

- ✅ **Creates** - When a new work order is created
- ✅ **Updates** - When any field changes
- ✅ **Deletes** - When a work order is destroyed
- ✅ **User** - Who made the change (via Current.user)
- ✅ **Changes** - Before and after values
- ✅ **Timestamp** - When the change occurred

## Viewing Audit Trail

### In Console

```ruby
# Get all audits for a work order
wo = WorkOrder.find(1)
wo.audits

# Get latest audit
wo.audits.last

# Get audit details
audit = wo.audits.last
audit.action          # "create", "update", or "destroy"
audit.user_id         # ID of user who made change
audit.user_type       # "User"
audit.audited_changes # Hash of changes: { "field" => [old, new] }
audit.created_at      # When change happened
audit.version         # Version number

# See all changes to work_order_status
wo.audits.where("audited_changes LIKE ?", "%work_order_status%")
```

### In Views (Example)

```erb
<h3>Change History</h3>
<table>
  <thead>
    <tr>
      <th>Date</th>
      <th>User</th>
      <th>Action</th>
      <th>Changes</th>
    </tr>
  </thead>
  <tbody>
    <% @work_order.audits.order(created_at: :desc).each do |audit| %>
      <tr>
        <td><%= audit.created_at.strftime("%Y-%m-%d %H:%M") %></td>
        <td><%= audit.user&.name || "System" %></td>
        <td><%= audit.action.capitalize %></td>
        <td>
          <% audit.audited_changes.each do |field, values| %>
            <%= field %>: <%= values[0] %> → <%= values[1] %><br>
          <% end %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

## Common Queries

```ruby
# All audits for a specific user
Audited::Audit.where(user_id: user.id)

# All work order audits
Audited::Audit.where(auditable_type: 'WorkOrder')

# Recent changes (last 24 hours)
Audited::Audit.where('created_at > ?', 24.hours.ago)

# Find who approved a work order
WorkOrder.find(1).audits.where("audited_changes LIKE ?", "%approved%").first

# Find all status changes
Audited::Audit.where("audited_changes LIKE ?", "%work_order_status%")
```

## Integration with AASM

Audited works seamlessly with AASM state transitions:

```ruby
wo = WorkOrder.first
wo.mark_complete!  # AASM transition

# This creates TWO audit records:
# 1. Audited's automatic audit of the status change
# 2. WorkOrderHistory record (from AASM callback)

wo.audits.last.audited_changes
# => {"work_order_status" => ["ongoing", "pending"]}
```

## Disabling Auditing (for seeds/tests)

```ruby
# Disable globally
Audited.auditing_enabled = false

# Your code here...

# Re-enable
Audited.auditing_enabled = true

# Disable for specific block
WorkOrder.without_auditing do
  # Changes here won't be audited
  WorkOrder.update_all(some_field: 'value')
end
```

## Checking if Auditing is Enabled

```ruby
Audited.auditing_enabled
# => true or false

WorkOrder.auditing_enabled
# => true or false
```

## Key Points

1. ✅ **Automatic** - No need to manually create audit records
2. ✅ **Comprehensive** - Tracks all create/update/destroy operations
3. ✅ **User Tracking** - Links changes to users via `Current.user`
4. ✅ **Queryable** - Easy to search and filter audit history
5. ✅ **Performance** - Minimal overhead, stores data efficiently
6. ⚠️ **YAML Issue** - In seeds, disable auditing to avoid YAML serialization errors
7. ⚠️ **Current.user** - Must be set in controllers for user tracking

## Troubleshooting

### No user_id in audits

**Problem**: Audits show `user_id: nil`  
**Solution**: Set `Current.user` in controller or before_action

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

### YAML serialization errors in seeds

**Problem**: `Psych::DisallowedClass: Tried to dump unspecified class: Date`  
**Solution**: Disable auditing in seeds (already done in our seeds.rb)

```ruby
Audited.auditing_enabled = false
# ... seed data creation ...
Audited.auditing_enabled = true
```

## Test Results

Based on our test run:

✅ **Audited is working correctly!**

- Updates are being tracked
- Changes are captured: `{"work_order_status" => ["ongoing", "pending"]}`
- Timestamps are recorded
- Action types are correct ("update")

⚠️ **User tracking needs setup** - `Current.user` must be set in controllers for full functionality
