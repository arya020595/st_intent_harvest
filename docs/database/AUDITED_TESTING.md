# Audited Gem - Audit Trail Guide

## Overview

Audited is an ORM extension that automatically tracks changes to your ActiveRecord models, creating a comprehensive audit trail of **who** changed **what** and **when**.

### Why Use Audited?

- 📝 **Compliance** - Meet regulatory requirements for data change tracking
- 🔍 **Debugging** - Easily trace when and how data changed
- 👤 **Accountability** - Know exactly who made each change
- 📊 **Reporting** - Generate audit reports for stakeholders
- ⏮️ **Recovery** - Understand data history to recover from mistakes

---

## Quick Start

### Enable Auditing in Models

Models that need audit tracking must include the `audited` declaration:

```ruby
class WorkOrder < ApplicationRecord
  # This single line enables full audit tracking
  audited

  # Rest of model code...
end
```

**Currently audited models in this application:**

- `WorkOrder` - Tracks all work order changes
- (Add other models here as needed)

---

## How It Works

### Automatic Tracking

When you perform any of these operations on an audited model:

```ruby
# CREATE
WorkOrder.create!(start_date: Date.today, work_order_status: 'ongoing')
# → Creates audit with action: "create"

# UPDATE
work_order.update!(work_order_status: 'pending')
# → Creates audit with action: "update", shows old → new values

# DESTROY
work_order.destroy!
# → Creates audit with action: "destroy"
```

Audited automatically creates a record in the `audits` table containing:

- `action` - What happened: create, update, or destroy
- `audited_changes` - What changed: `{ "field" => [old_value, new_value] }`
- `user_id` - Who made the change (if Current.user is set)
- `created_at` - When it happened
- `version` - Version number (increments with each change)

### User Tracking

**Important:** Audited tracks users via `Current.user`. This is **already configured** in `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

**What this means:**

- ✅ **Web requests** - User is automatically tracked (via Devise authentication)
- ✅ **API requests** - User tracked if authentication is set up
- ❌ **Console commands** - User is `nil` unless you manually set `Current.user`
- ❌ **Background jobs** - User is `nil` unless explicitly set

---

## Testing Audited

### Method 1: Rails Console

The most direct way to test audit functionality:

```bash
docker compose exec web rails console
```

```ruby
# IMPORTANT: Set current user first for user tracking
Current.user = User.find_by(email: 'conductor@example.com')

# Example 1: Update a work order
wo = WorkOrder.first
wo.update!(work_order_status: 'pending')

# View the audit that was just created
audit = wo.audits.last
puts "Action: #{audit.action}"
puts "User: #{audit.user&.name || 'Not set'}"
puts "Changes: #{audit.audited_changes.inspect}"
puts "Time: #{audit.created_at}"

# Expected output:
# Action: update
# User: Field Conductor
# Changes: {"work_order_status"=>["ongoing", "pending"]}
# Time: 2025-10-27 01:30:00 UTC
```

### Method 2: Through the Web Interface

1. Log in as a user (e.g., conductor@example.com / password)
2. Navigate to a work order
3. Make a change (update status, modify fields, etc.)
4. Check the audit trail in the console:

```ruby
wo = WorkOrder.find(1)
wo.audits.each do |audit|
  puts "#{audit.created_at} - #{audit.user&.name}: #{audit.action}"
  puts "  Changes: #{audit.audited_changes}"
end
```

### Method 3: Using Test Script

Run the comprehensive test script:

```bash
docker compose exec web rails runner tmp/test_audited.rb
```

---

## Querying Audit Trail

### Basic Queries

```ruby
# Get all audits for a specific work order
wo = WorkOrder.find(1)
wo.audits.order(created_at: :desc)

# Get the latest audit
wo.audits.last

# Count total changes
wo.audits.count

# Get audits by action type
wo.audits.where(action: 'update')
wo.audits.where(action: 'create')
```

### Accessing Audit Details

```ruby
audit = WorkOrder.first.audits.last

# Basic information
audit.action          # => "create", "update", or "destroy"
audit.auditable_type  # => "WorkOrder"
audit.auditable_id    # => 1
audit.version         # => 1, 2, 3... (incremental)
audit.created_at      # => 2025-10-27 01:30:00 UTC

# User information
audit.user_id         # => 3
audit.user            # => #<User id: 3, name: "Field Conductor">
audit.user&.name      # => "Field Conductor" (safe navigation)

# Changes
audit.audited_changes
# => {"work_order_status" => ["ongoing", "pending"]}

# Get specific field change
audit.audited_changes["work_order_status"]
# => ["ongoing", "pending"]  (old value, new value)
```

### Advanced Queries

```ruby
# Find all audits by a specific user
user = User.find_by(email: 'conductor@example.com')
Audited::Audit.where(user_id: user.id).order(created_at: :desc)

# Find all work order audits
Audited::Audit.where(auditable_type: 'WorkOrder')

# Find recent changes (last 24 hours)
Audited::Audit.where('created_at > ?', 24.hours.ago)

# Find who changed a specific field
WorkOrder.find(1).audits.where(
  "audited_changes LIKE ?", "%work_order_status%"
)

# Find who approved work orders
Audited::Audit.where(
  auditable_type: 'WorkOrder'
).where(
  "audited_changes LIKE ?", "%approved%"
)

# Get all changes made today
Audited::Audit.where(
  'created_at >= ?', Date.today.beginning_of_day
).order(created_at: :desc)
```

---

## Displaying Audit Trail in Views

### Example: Change History Table

```erb
<div class="card">
  <div class="card-header">
    <h3>Change History</h3>
  </div>
  <div class="card-body">
    <% if @work_order.audits.any? %>
      <table class="table table-striped">
        <thead>
          <tr>
            <th>Date & Time</th>
            <th>User</th>
            <th>Action</th>
            <th>Changes</th>
          </tr>
        </thead>
        <tbody>
          <% @work_order.audits.order(created_at: :desc).each do |audit| %>
            <tr>
              <td>
                <%= audit.created_at.strftime("%Y-%m-%d %H:%M:%S") %>
              </td>
              <td>
                <%= audit.user&.name || "System" %>
              </td>
              <td>
                <span class="badge badge-<%= audit.action %>">
                  <%= audit.action.capitalize %>
                </span>
              </td>
              <td>
                <% audit.audited_changes.each do |field, values| %>
                  <strong><%= field.humanize %>:</strong>
                  <% if values.is_a?(Array) && values.length == 2 %>
                    <span class="text-muted"><%= values[0] || 'nil' %></span>
                    →
                    <span class="text-success"><%= values[1] %></span>
                  <% else %>
                    <%= values %>
                  <% end %>
                  <br>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p class="text-muted">No changes recorded yet.</p>
    <% end %>
  </div>
</div>
```

### Example: Recent Activity Widget

```erb
<div class="recent-activity">
  <h4>Recent Activity</h4>
  <ul class="list-unstyled">
    <% Audited::Audit.where(auditable_type: 'WorkOrder')
                     .order(created_at: :desc)
                     .limit(10).each do |audit| %>
      <li>
        <small class="text-muted">
          <%= time_ago_in_words(audit.created_at) %> ago
        </small>
        <br>
        <strong><%= audit.user&.name || "System" %></strong>
        <%= audit.action %>d
        Work Order #<%= audit.auditable_id %>
      </li>
    <% end %>
  </ul>
</div>
```

---

## Integration with AASM State Machine

Audited works seamlessly with AASM state transitions. When you use AASM events, you get **both**:

1. **Audited audit** - Automatic tracking of the status field change
2. **WorkOrderHistory** - Custom history record (from AASM callback)

### Example

```ruby
wo = WorkOrder.first  # status: "ongoing"

# Use AASM event to change status
wo.mark_complete!

# Check Audited's audit
wo.audits.last.audited_changes
# => {"work_order_status" => ["ongoing", "pending"]}

# Check WorkOrderHistory (AASM callback)
wo.work_order_histories.last
# => Custom history record with transition details
```

**Benefits:**

- Audited provides the technical audit trail
- WorkOrderHistory provides business-context logging
- Both complement each other for complete tracking

---

## Disabling Auditing

### Why Disable Auditing?

You may want to disable auditing temporarily for:

- **Seed data** - Avoid YAML serialization issues
- **Bulk updates** - Performance optimization
- **Data migrations** - Don't pollute audit history

### Global Disable/Enable

```ruby
# Disable auditing globally
Audited.auditing_enabled = false

# Perform your operations
WorkOrder.update_all(some_field: 'value')

# Re-enable auditing
Audited.auditing_enabled = true
```

### Block-Level Disable

```ruby
# Disable only for this block
WorkOrder.without_auditing do
  # These changes won't be audited
  wo = WorkOrder.first
  wo.update!(field: 'value')
  WorkOrder.update_all(another_field: 'another_value')
end

# Auditing automatically re-enabled after block
```

### Check Auditing Status

```ruby
# Check if auditing is enabled globally
Audited.auditing_enabled
# => true or false

# Check if auditing is enabled for specific model
WorkOrder.auditing_enabled
# => true or false
```

---

## Common Use Cases

### Use Case 1: Who Changed This?

```ruby
# Find who last modified a work order
wo = WorkOrder.find(1)
last_audit = wo.audits.where(action: 'update').last
puts "Last modified by: #{last_audit.user&.name}"
puts "On: #{last_audit.created_at}"
```

### Use Case 2: Status Change History

```ruby
# Get all status changes for a work order
wo = WorkOrder.find(1)
status_changes = wo.audits.where(
  "audited_changes LIKE ?", "%work_order_status%"
)

status_changes.each do |audit|
  old_status, new_status = audit.audited_changes["work_order_status"]
  puts "#{audit.created_at}: #{old_status} → #{new_status} by #{audit.user&.name}"
end
```

### Use Case 3: Compliance Report

```ruby
# Generate a report of all changes in the last month
start_date = 1.month.ago
audits = Audited::Audit.where(
  auditable_type: 'WorkOrder',
  created_at: start_date..Time.current
).includes(:user)

audits.group_by(&:user).each do |user, user_audits|
  puts "#{user&.name || 'System'}: #{user_audits.count} changes"
end
```

### Use Case 4: Rollback Information

```ruby
# See what a record looked like before the last change
wo = WorkOrder.find(1)
last_audit = wo.audits.last

if last_audit.action == 'update'
  last_audit.audited_changes.each do |field, values|
    old_value, new_value = values
    puts "#{field} was '#{old_value}' before the change"
  end
end
```

---

## Troubleshooting

### Issue: `user_id` is `nil` in Audits

**Symptom:**

```ruby
audit.user_id  # => nil
```

**Cause:** `Current.user` is not set when the change is made.

**Solution:**

**For Console/Scripts:**

```ruby
# Set Current.user before making changes
Current.user = User.find_by(email: 'conductor@example.com')
wo.update!(status: 'pending')  # Now user_id will be set
```

**For Controllers:**
Already configured in `ApplicationController`:

```ruby
before_action :set_current_user

def set_current_user
  Current.user = current_user if user_signed_in?
end
```

**For Background Jobs:**

```ruby
class SomeJob < ApplicationJob
  def perform(work_order_id, user_id)
    Current.user = User.find(user_id)
    # Now changes will be tracked with this user
    work_order = WorkOrder.find(work_order_id)
    work_order.update!(status: 'completed')
  end
end
```

### Issue: YAML Serialization Errors in Seeds

**Symptom:**

```
Psych::DisallowedClass: Tried to dump unspecified class: Date
```

**Cause:** Audited tries to serialize Date objects to YAML during seeds.

**Solution:** Already implemented in `db/seeds.rb`:

```ruby
# Disable auditing during seeds
Audited.auditing_enabled = false

# Seed data...

# Re-enable auditing
Audited.auditing_enabled = true
```

### Issue: Too Many Audit Records

**Symptom:** Audit table growing too large, impacting performance.

**Solutions:**

1. **Archive old audits:**

   ```ruby
   # Archive audits older than 1 year
   Audited::Audit.where('created_at < ?', 1.year.ago).delete_all
   ```

2. **Selective auditing:**

   ```ruby
   # Only audit specific columns
   class WorkOrder < ApplicationRecord
     audited only: [:work_order_status, :approved_by, :approved_at]
   end
   ```

3. **Exclude columns:**
   ```ruby
   # Audit everything except these columns
   class WorkOrder < ApplicationRecord
     audited except: [:created_at, :updated_at]
   end
   ```

---

## Best Practices

1. **Always Set Current.user** - Ensure user tracking works properly

   ```ruby
   before_action :set_current_user  # In ApplicationController
   ```

2. **Use Descriptive Comments** - Add context to important changes

   ```ruby
   wo.update!(status: 'approved', audit_comment: 'Approved after review')
   ```

3. **Regular Cleanup** - Archive or delete old audits periodically

   ```ruby
   # In a scheduled job
   Audited::Audit.where('created_at < ?', 2.years.ago).delete_all
   ```

4. **Selective Auditing** - Only audit fields that matter

   ```ruby
   audited only: [:important_field_1, :important_field_2]
   ```

5. **Display Audit Trail** - Show users the change history in the UI

6. **Test Audit Functionality** - Verify auditing works in your tests
   ```ruby
   test "should audit status change" do
     assert_difference 'work_order.audits.count', 1 do
       work_order.update!(status: 'pending')
     end
   end
   ```

---

## Summary

✅ **Audited is fully configured and working** in this application  
✅ **User tracking works automatically** in controllers (via `Current.user`)  
✅ **Console testing requires** manual `Current.user` setup  
✅ **AASM integration** provides dual tracking (Audited + WorkOrderHistory)  
✅ **Performance impact** is minimal with proper cleanup

**Key Takeaway:** The `user_id: nil` you see in console tests is **normal and expected**. In production, when users interact with the web interface, `user_id` will be automatically tracked! 🎯
