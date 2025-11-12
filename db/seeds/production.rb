# Production Seeds - Minimal essential data only
# Usage: rails db:seed:production

puts '🌱 Starting production seed process...'

# Disable auditing during seeds
Audited.auditing_enabled = false

# Create Permissions
puts 'Creating permissions...'

# All permissions array (same as main seeds.rb)
user_management_user_permissions = [
  { subject: 'UserManagement::User', action: 'index', description: 'View users list' },
  { subject: 'UserManagement::User', action: 'show', description: 'View user details' },
  { subject: 'UserManagement::User', action: 'create', description: 'Create new users' },
  { subject: 'UserManagement::User', action: 'update', description: 'Edit users' },
  { subject: 'UserManagement::User', action: 'destroy', description: 'Delete users' }
]

user_management_role_permissions = [
  { subject: 'UserManagement::Role', action: 'index', description: 'View roles list' },
  { subject: 'UserManagement::Role', action: 'show', description: 'View role details' },
  { subject: 'UserManagement::Role', action: 'create', description: 'Create new roles' },
  { subject: 'UserManagement::Role', action: 'update', description: 'Edit roles' },
  { subject: 'UserManagement::Role', action: 'destroy', description: 'Delete roles' }
]

worker_permissions = [
  { subject: 'Worker', action: 'index', description: 'View workers list' },
  { subject: 'Worker', action: 'show', description: 'View worker details' },
  { subject: 'Worker', action: 'new', description: 'View new worker form' },
  { subject: 'Worker', action: 'create', description: 'Add new workers' },
  { subject: 'Worker', action: 'edit', description: 'View edit worker form' },
  { subject: 'Worker', action: 'update', description: 'Edit workers' },
  { subject: 'Worker', action: 'destroy', description: 'Remove workers' }
]

vehicle_permissions = [
  { subject: 'MasterData::Vehicle', action: 'index', description: 'View vehicles list' },
  { subject: 'MasterData::Vehicle', action: 'show', description: 'View vehicle details' },
  { subject: 'MasterData::Vehicle', action: 'create', description: 'Register vehicles' },
  { subject: 'MasterData::Vehicle', action: 'update', description: 'Update vehicles' },
  { subject: 'MasterData::Vehicle', action: 'destroy', description: 'Deactivate vehicles' }
]

block_permissions = [
  { subject: 'MasterData::Block', action: 'index', description: 'View blocks list' },
  { subject: 'MasterData::Block', action: 'show', description: 'View block details' },
  { subject: 'MasterData::Block', action: 'create', description: 'Create blocks' },
  { subject: 'MasterData::Block', action: 'update', description: 'Update blocks' },
  { subject: 'MasterData::Block', action: 'destroy', description: 'Delete blocks' }
]

work_order_rate_permissions = [
  { subject: 'MasterData::WorkOrderRate', action: 'index', description: 'View work order rates list' },
  { subject: 'MasterData::WorkOrderRate', action: 'show', description: 'View work order rate details' },
  { subject: 'MasterData::WorkOrderRate', action: 'create', description: 'Create work order rates' },
  { subject: 'MasterData::WorkOrderRate', action: 'update', description: 'Update work order rates' },
  { subject: 'MasterData::WorkOrderRate', action: 'destroy', description: 'Delete work order rates' }
]

unit_permissions = [
  { subject: 'MasterData::Unit', action: 'index', description: 'View units list' },
  { subject: 'MasterData::Unit', action: 'show', description: 'View unit details' },
  { subject: 'MasterData::Unit', action: 'create', description: 'Create units' },
  { subject: 'MasterData::Unit', action: 'update', description: 'Update units' },
  { subject: 'MasterData::Unit', action: 'destroy', description: 'Delete units' }
]

category_permissions = [
  { subject: 'MasterData::Category', action: 'index', description: 'View categories list' },
  { subject: 'MasterData::Category', action: 'show', description: 'View category details' },
  { subject: 'MasterData::Category', action: 'create', description: 'Create categories' },
  { subject: 'MasterData::Category', action: 'update', description: 'Update categories' },
  { subject: 'MasterData::Category', action: 'destroy', description: 'Delete categories' }
]

inventory_permissions = [
  { subject: 'Inventory', action: 'index', description: 'View inventories list' },
  { subject: 'Inventory', action: 'show', description: 'View inventory details' },
  { subject: 'Inventory', action: 'create', description: 'Create inventories' },
  { subject: 'Inventory', action: 'update', description: 'Edit inventories' },
  { subject: 'Inventory', action: 'destroy', description: 'Delete inventories' }
]

payslip_permissions = [
  { subject: 'Payslip', action: 'index', description: 'View payslips list' },
  { subject: 'Payslip', action: 'show', description: 'View payslip details' }
]

work_order_detail_permissions = [
  { subject: 'WorkOrder::Detail', action: 'index', description: 'View work orders list' },
  { subject: 'WorkOrder::Detail', action: 'show', description: 'View work order details' },
  { subject: 'WorkOrder::Detail', action: 'create', description: 'Create work orders' },
  { subject: 'WorkOrder::Detail', action: 'update', description: 'Edit work orders' },
  { subject: 'WorkOrder::Detail', action: 'destroy', description: 'Delete work orders' },
  { subject: 'WorkOrder::Detail', action: 'mark_complete', description: 'Mark work order as complete' }
]

work_order_approval_permissions = [
  { subject: 'WorkOrder::Approval', action: 'index', description: 'View work orders for approval' },
  { subject: 'WorkOrder::Approval', action: 'show', description: 'View approval details' },
  { subject: 'WorkOrder::Approval', action: 'approve', description: 'Approve work orders' },
  { subject: 'WorkOrder::Approval', action: 'reject', description: 'Reject work orders' }
]

work_order_pay_calc_permissions = [
  { subject: 'WorkOrder::PayCalculation', action: 'index', description: 'View pay calculations list' },
  { subject: 'WorkOrder::PayCalculation', action: 'show', description: 'View pay calculation details' },
  { subject: 'WorkOrder::PayCalculation', action: 'create', description: 'Create pay calculations' },
  { subject: 'WorkOrder::PayCalculation', action: 'update', description: 'Update pay calculations' },
  { subject: 'WorkOrder::PayCalculation', action: 'destroy', description: 'Delete pay calculations' }
]

dashboard_permissions = [
  { subject: 'Dashboard', action: 'index', description: 'View dashboard' },
  { subject: 'Dashboard', action: 'show', description: 'View dashboard details' }
]

# Combine all permissions
all_permissions = [
  *user_management_user_permissions,
  *user_management_role_permissions,
  *worker_permissions,
  *dashboard_permissions,
  *vehicle_permissions,
  *block_permissions,
  *work_order_rate_permissions,
  *unit_permissions,
  *category_permissions,
  *inventory_permissions,
  *payslip_permissions,
  *work_order_detail_permissions,
  *work_order_approval_permissions,
  *work_order_pay_calc_permissions
].flatten

all_permissions.each do |perm|
  Permission.find_or_create_by!(subject: perm[:subject], action: perm[:action])
end
puts "✓ Created #{Permission.count} permissions"

# Create Roles
puts 'Creating roles...'

superadmin_role = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access (bypasses all permission checks)'
end

manager_role = Role.find_or_create_by!(name: 'Manager') do |role|
  role.description = 'Can view dashboard and approve work orders'
end
manager_permissions = Permission.where(subject: ['Dashboard', 'WorkOrder::Approval'])
manager_role.permissions = manager_permissions

field_conductor_role = Role.find_or_create_by!(name: 'Field Conductor') do |role|
  role.description = 'Can create and manage work order details'
end
field_conductor_permissions = Permission.where(subject: ['WorkOrder::Detail'])
field_conductor_role.permissions = field_conductor_permissions

clerk_role = Role.find_or_create_by!(name: 'Clerk') do |role|
  role.description = 'Can manage pay calculations, payslips, inventories, workers, and master data'
end
clerk_permissions = Permission.where(subject: [
                                       'WorkOrder::PayCalculation',
                                       'Payslip',
                                       'Inventory',
                                       'Worker',
                                       'MasterData::Vehicle',
                                       'MasterData::Block',
                                       'MasterData::WorkOrderRate',
                                       'MasterData::Unit',
                                       'MasterData::Category'
                                     ])
clerk_role.permissions = clerk_permissions

puts "✓ Created #{Role.count} roles"

# Create ONLY Superadmin user for production
puts 'Creating admin user...'

User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.name = 'Administrator'
  user.password = 'ChangeMe123!' # MUST change after first login
  user.password_confirmation = 'ChangeMe123!'
  user.role = superadmin_role
end

puts '✓ Created admin user'

# Create essential Units
puts 'Creating units...'
units_data = [
  { name: 'Kg', unit_type: 'Weight' },
  { name: 'Liter', unit_type: 'Volume' },
  { name: 'Piece', unit_type: 'Count' },
  { name: 'Hour', unit_type: 'Time' },
  { name: 'Day', unit_type: 'Time' },
  { name: 'Hectare', unit_type: 'Area' },
  { name: 'Ton', unit_type: 'Weight' }
]

units_data.each do |unit_data|
  Unit.find_or_create_by!(unit_data)
end
puts "✓ Created #{Unit.count} units"

# Create essential Categories
puts 'Creating categories...'
Category.find_or_create_by!(name: 'Materials', category_type: 'Inventory')
Category.find_or_create_by!(name: 'Tools', category_type: 'Inventory')
Category.find_or_create_by!(name: 'Equipment', category_type: 'Inventory')

puts "✓ Created #{Category.count} categories"

# Re-enable auditing
Audited.auditing_enabled = true

puts "\n🎉 Production seeding completed!"
puts "\n📊 Summary:"
puts "  Permissions: #{Permission.count}"
puts "  Roles: #{Role.count}"
puts "  Users: #{User.count}"
puts "  Units: #{Unit.count}"
puts "  Categories: #{Category.count}"
puts "\n👤 Admin User:"
puts '  Email: admin@example.com'
puts '  Password: ChangeMe123!'
puts "\n⚠️  IMPORTANT: Change the admin password immediately after first login!"
