# frozen_string_literal: true

# Production Seeds - Roles with Permissions
# Create roles and assign permissions efficiently

puts '👥 Creating roles...'

# Fetch all permissions once
all_permissions = Permission.pluck(:code, :id).to_h

# Define role configurations
role_configs = [
  {
    name: 'Superadmin',
    description: 'Full system access with all permissions',
    permission_codes: all_permissions.keys # All permissions
  },
  {
    name: 'Manager',
    description: 'Can approve work orders and manage approvals',
    permission_codes: [
      'dashboard.index',
      'work_orders.approvals.index',
      'work_orders.approvals.show',
      'work_orders.approvals.update',
      'work_orders.approvals.approve',
      'work_orders.approvals.request_amendment'
    ]
  },
  {
    name: 'Field Supervisor',
    description: 'Can manage work order details in the field',
    permission_codes: [
      'work_orders.details.index',
      'work_orders.details.show',
      'work_orders.details.new',
      'work_orders.details.create',
      'work_orders.details.edit',
      'work_orders.details.update',
      'work_orders.details.destroy',
      'work_orders.details.mark_complete'
    ]
  },
  {
    name: 'Clerk',
    description: 'Can manage administrative tasks, apply work orders, calculations, and master data',
    permission_codes: [
      'work_orders.details.index',
      'work_orders.details.show',
      'work_orders.details.new',
      'work_orders.details.create',
      'work_orders.details.edit',
      'work_orders.details.update',
      'work_orders.details.destroy',
      'work_orders.details.mark_complete',
      'work_orders.pay_calculations.index',
      'work_orders.pay_calculations.show',
      'work_orders.pay_calculations.new',
      'work_orders.pay_calculations.create',
      'work_orders.pay_calculations.edit',
      'work_orders.pay_calculations.update',
      'work_orders.pay_calculations.destroy',
      'work_orders.pay_calculations.worker_detail',
      'payslip.index',
      'payslip.show',
      'payslip.export',
      'inventory.index',
      'inventory.show',
      'inventory.new',
      'inventory.create',
      'inventory.edit',
      'inventory.update',
      'inventory.destroy',
      'workers.index',
      'workers.show',
      'workers.new',
      'workers.create',
      'workers.edit',
      'workers.update',
      'workers.destroy',
      'master_data.blocks.index',
      'master_data.blocks.show',
      'master_data.blocks.new',
      'master_data.blocks.create',
      'master_data.blocks.edit',
      'master_data.blocks.update',
      'master_data.blocks.destroy',
      'master_data.categories.index',
      'master_data.categories.show',
      'master_data.categories.new',
      'master_data.categories.create',
      'master_data.categories.edit',
      'master_data.categories.update',
      'master_data.categories.destroy',
      'master_data.units.index',
      'master_data.units.show',
      'master_data.units.new',
      'master_data.units.create',
      'master_data.units.edit',
      'master_data.units.update',
      'master_data.units.destroy',
      'master_data.vehicles.index',
      'master_data.vehicles.show',
      'master_data.vehicles.new',
      'master_data.vehicles.create',
      'master_data.vehicles.edit',
      'master_data.vehicles.update',
      'master_data.vehicles.destroy',
      'master_data.work_order_rates.index',
      'master_data.work_order_rates.show',
      'master_data.work_order_rates.new',
      'master_data.work_order_rates.create',
      'master_data.work_order_rates.edit',
      'master_data.work_order_rates.update',
      'master_data.work_order_rates.destroy'
    ]
  }
]

# Create roles with permissions in batch
role_configs.each do |config|
  role = Role.find_or_create_by!(name: config[:name]) do |r|
    r.description = config[:description]
  end

  # Get permission IDs for this role
  permission_ids = config[:permission_codes].map { |code| all_permissions[code] }.compact

  # Batch insert role-permission associations
  existing_associations = RolesPermission.where(role_id: role.id).pluck(:permission_id)
  new_permission_ids = permission_ids - existing_associations

  if new_permission_ids.any?
    roles_permissions_data = new_permission_ids.map do |permission_id|
      { role_id: role.id, permission_id: permission_id, created_at: Time.current, updated_at: Time.current }
    end

    RolesPermission.insert_all(roles_permissions_data) if roles_permissions_data.any?
  end

  puts "  ✓ #{role.name}: #{permission_ids.count} permissions"
end

puts "✓ Created #{Role.count} roles with permissions"
