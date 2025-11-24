# frozen_string_literal: true

# Permission Seeds
# Format: namespace.resource.action
# Example: admin.users.index = "View Users"

puts 'Seeding Permissions...'

# Define resources with their actions (using Rails standard actions)
resources = {
  # Dashboard
  'dashboard' => %w[index],

  # Work Orders namespace
  'work_orders.details' => %w[index show new create edit update destroy mark_complete],
  'work_orders.approvals' => %w[index show update approve request_amendment],
  'work_orders.pay_calculations' => %w[index show new create edit update destroy worker_detail],

  # Payslip
  'payslip' => %w[index show export],

  # Inventory
  'inventory' => %w[index show new create edit update destroy],

  # Workers
  'workers' => %w[index show new create edit update destroy],

  # Master Data namespace
  'master_data.blocks' => %w[index show new create edit update destroy],
  'master_data.categories' => %w[index show new create edit update destroy],
  'master_data.units' => %w[index show new create edit update destroy],
  'master_data.vehicles' => %w[index show new create edit update destroy],
  'master_data.work_order_rates' => %w[index show new create edit update destroy]
}

# Action name mappings for better readability
action_names = {
  'index' => 'List',
  'show' => 'View',
  'new' => 'New',
  'create' => 'Create',
  'edit' => 'Edit',
  'update' => 'Update',
  'destroy' => 'Delete',
  'approve' => 'Approve',
  'export' => 'Export',
  'mark_complete' => 'Mark Complete',
  'request_amendment' => 'Request Amendment',
  'worker_detail' => 'Worker Detail'
}

created_count = 0
updated_count = 0

resources.each do |resource, actions|
  actions.each do |action|
    code = "#{resource}.#{action}"

    # Generate human-readable name
    # "dashboard.index" => "List Dashboard"
    # "work_orders.details.create" => "Create Work Orders Details"
    # "master_data.blocks.show" => "View Master Data Blocks"
    resource_parts = resource.split('.')

    if resource_parts.length == 1
      # Single resource like "dashboard", "payslip", "inventory", "workers"
      resource_name = resource_parts[0].titleize
      action_name = action_names[action] || action.titleize
      name = "#{action_name} #{resource_name}"
    else
      # Namespaced resource like "work_orders.details", "master_data.blocks"
      namespace = resource_parts[0].gsub('_', ' ').titleize
      resource_name = resource_parts[1].gsub('_', ' ').titleize
      action_name = action_names[action] || action.titleize
      name = "#{action_name} #{namespace} #{resource_name}"
    end

    permission = Permission.find_or_initialize_by(code: code)

    if permission.new_record?
      permission.assign_attributes(
        name: name,
        resource: resource
      )
      permission.save!
      created_count += 1
      print '.'
    elsif permission.name != name || permission.resource != resource
      permission.update!(
        name: name,
        resource: resource
      )
      updated_count += 1
      print 'u'
    else
      print '-'
    end
  end
end

puts "\n✓ Permissions seeded successfully!"
puts "  Created: #{created_count}"
puts "  Updated: #{updated_count}"
puts "  Total: #{Permission.count}"
