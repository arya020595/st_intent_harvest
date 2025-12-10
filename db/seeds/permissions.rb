# frozen_string_literal: true

puts 'Seeding Permissions...'

# Define resources with their actions
resources = {
  'dashboard' => %w[index],

  'work_orders.details' => %w[index show create update destroy mark_complete],
  'work_orders.approvals' => %w[index show update approve request_amendment],
  'work_orders.pay_calculations' => %w[index show create update destroy worker_detail],

  'payslip' => %w[show],
  'inventory' => %w[index show create update destroy],
  'workers' => %w[index show create update destroy],

  'master_data.blocks' => %w[index show create update destroy],
  'master_data.categories' => %w[index show create update destroy],
  'master_data.units' => %w[index show create update destroy],
  'master_data.vehicles' => %w[index show create update destroy],
  'master_data.work_order_rates' => %w[index show create update destroy],

  'user_management.roles' => %w[index show create update destroy],
  'user_management.users' => %w[index show create update destroy]
}

# Section mapping
SECTION_MAPPING = {
  'dashboard' => 'Dashboard',
  'work_orders' => 'Work Order',
  'payslip' => 'Payslip',
  'inventory' => 'Inventory',
  'workers' => 'Workers List',
  'master_data' => 'Master Data',
  'user_management' => 'User Management'
}.freeze

# Custom action name mapping
ACTION_NAME_MAPPING = {
  'index' => 'list',
  'show' => 'view',
  'destroy' => 'delete',
  'request_amendment' => 'request amendment',
  'worker_detail' => 'worker detail',
  'mark_complete' => 'mark complete'
}.freeze

created_count = 0
updated_count = 0

resources.each do |resource, actions|
  actions.each do |action|
    code = "#{resource}.#{action}"

    # Determine section
    resource_root = resource.split('.').first
    section = SECTION_MAPPING[resource_root] || 'General'

    # Set name: use mapping for index/show, otherwise lowercase
    name = ACTION_NAME_MAPPING[action] || action.downcase

    permission = Permission.find_or_initialize_by(code: code)

    if permission.new_record?
      permission.assign_attributes(
        name: name,
        resource: resource,
        section: section
      )
      permission.save!
      created_count += 1
      print '.'
    elsif permission.name != name || permission.resource != resource || permission.section != section
      permission.update!(
        name: name,
        resource: resource,
        section: section
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
