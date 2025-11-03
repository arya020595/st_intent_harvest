# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts '🌱 Starting seed process...'

# Disable auditing during seeds to avoid YAML serialization issues
Audited.auditing_enabled = false

# Clean up existing data (in reverse order of dependencies)
puts 'Cleaning up existing data...'
PayCalculationDetail.destroy_all
PayCalculation.destroy_all
WorkOrderItem.destroy_all
WorkOrderWorker.destroy_all
WorkOrder.destroy_all
Inventory.destroy_all
WorkOrderRate.destroy_all
User.destroy_all
RolesPermission.destroy_all
Role.destroy_all
Permission.destroy_all
Worker.destroy_all
Block.destroy_all
Vehicle.destroy_all
Unit.destroy_all
Category.destroy_all

# Create Permissions
puts 'Creating permissions...'

# UserManagement namespaced permissions
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

# Worker permissions (non-namespaced)
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

# Namespaced WorkOrder permissions
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

# Dashboard permissions (for accessing the main dashboard)
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

# Superadmin - bypasses all permission checks
superadmin_role = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access (bypasses all permission checks)'
end
# No need to assign permissions - superadmin bypasses permission checks

# Manager - can view dashboard and approve work orders
manager_role = Role.find_or_create_by!(name: 'Manager') do |role|
  role.description = 'Can view dashboard and approve work orders'
end
manager_permissions = Permission.where(subject: ['Dashboard', 'WorkOrder::Approval'])
manager_role.permissions = manager_permissions

# Field Conductor - can create and manage work order details (NO dashboard access)
field_conductor_role = Role.find_or_create_by!(name: 'Field Conductor') do |role|
  role.description = 'Can create and manage work order details'
end
field_conductor_permissions = Permission.where(subject: ['WorkOrder::Detail'])
field_conductor_role.permissions = field_conductor_permissions

# Clerk - administrative support with managed access to pay calculations, payslips, inventories, workers, and master data (NO dashboard access)
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

# Create Users
puts 'Creating users...'

# Superadmin user
User.find_or_create_by!(email: 'superadmin@example.com') do |user|
  user.name = 'Super Admin'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = superadmin_role
end

# Manager user
User.find_or_create_by!(email: 'manager@example.com') do |user|
  user.name = 'Manager User'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = manager_role
end

# Field Conductor user
User.find_or_create_by!(email: 'conductor@example.com') do |user|
  user.name = 'Field Conductor'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = field_conductor_role
end

# Clerk user
User.find_or_create_by!(email: 'clerk@example.com') do |user|
  user.name = 'Clerk User'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = clerk_role
end

puts "✓ Created #{User.count} users"

# Create Units
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

# Create Categories
puts 'Creating categories...'
material_category = Category.find_or_create_by!(name: 'Materials', category_type: 'Inventory')
fertilizer_category = Category.find_or_create_by!(name: 'Fertilizers', category_type: 'Inventory',
                                                  parent: material_category)
pesticide_category = Category.find_or_create_by!(name: 'Pesticides', category_type: 'Inventory',
                                                 parent: material_category)
tools_category = Category.find_or_create_by!(name: 'Tools', category_type: 'Inventory')
equipment_category = Category.find_or_create_by!(name: 'Equipment', category_type: 'Inventory')

puts "✓ Created #{Category.count} categories"

# Create Blocks
puts 'Creating blocks...'
10.times do |i|
  block_number = "BLK-#{(i + 1).to_s.rjust(3, '0')}"

  Block.find_or_create_by!(block_number: block_number) do |block|
    block.hectarage = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(5.0, 50.0)
  end
end
puts "✓ Created #{Block.count} blocks"

# Create Vehicles
puts 'Creating vehicles...'
vehicle_models = [
  'Toyota Hilux', 'Isuzu D-Max', 'Mitsubishi Triton', 'Ford Ranger',
  'Nissan Navara', 'Mazda BT-50', 'Chevrolet Colorado'
]

10.times do |i|
  vehicle_number = "VH-#{(i + 1).to_s.rjust(3, '0')}"

  Vehicle.find_or_create_by!(vehicle_number: vehicle_number) do |vehicle|
    vehicle.vehicle_model = vehicle_models.sample
  end
end
puts "✓ Created #{Vehicle.count} vehicles"

# Create Workers
puts 'Creating workers...'
worker_types = ['Part - Time', 'Full - Time']
genders = %w[Male Female]
nationalities = %w[Indonesian Malaysian Filipino Thai Vietnamese]

50.times do |i|
  identity_number = "ID-#{(i + 1).to_s.rjust(3, '0')}"

  Worker.find_or_create_by!(identity_number: identity_number) do |worker|
    worker.name = Faker::Name.name
    worker.worker_type = worker_types.sample
    worker.gender = genders.sample
    worker.is_active = [true, true, true, false].sample # 75% active, 25% inactive
    worker.hired_date = Faker::Date.between(from: 10.years.ago, to: Date.today)
    worker.nationality = nationalities.sample
  end
end
puts "✓ Created #{Worker.count} workers"

# Create Inventories
puts 'Creating inventories...'
kg_unit = Unit.find_by(name: 'Kg')
liter_unit = Unit.find_by(name: 'Liter')
piece_unit = Unit.find_by(name: 'Piece')

# Fertilizer inventories
fertilizer_names = ['NPK Fertilizer', 'Organic Fertilizer', 'Urea Fertilizer', 'Compost', 'Phosphate Fertilizer']
fertilizer_names.each do |name|
  Inventory.find_or_create_by!(name: name) do |inventory|
    inventory.stock_quantity = Faker::Number.between(from: 100, to: 500)
    inventory.category = fertilizer_category
    inventory.unit = kg_unit
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(45.0, 85.0)
    inventory.supplier = Faker::Company.name
    inventory.input_date = Faker::Date.between(from: 90.days.ago, to: Date.today)
  end
end

# Pesticide inventories
pesticide_names = ['Herbicide', 'Insecticide', 'Fungicide', 'Pesticide Mix']
pesticide_names.each do |name|
  Inventory.find_or_create_by!(name: name) do |inventory|
    inventory.stock_quantity = Faker::Number.between(from: 50, to: 200)
    inventory.category = pesticide_category
    inventory.unit = liter_unit
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(30.0, 60.0)
    inventory.supplier = Faker::Company.name
    inventory.input_date = Faker::Date.between(from: 90.days.ago, to: Date.today)
  end
end

# Tools inventories
tool_names = ['Harvesting Knife', 'Pruning Shears', 'Hand Trowel', 'Garden Hoe', 'Machete']
tool_names.each do |name|
  Inventory.find_or_create_by!(name: name) do |inventory|
    inventory.stock_quantity = Faker::Number.between(from: 20, to: 100)
    inventory.category = tools_category
    inventory.unit = piece_unit
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(15.0, 50.0)
    inventory.supplier = Faker::Company.name
    inventory.input_date = Faker::Date.between(from: 180.days.ago, to: Date.today)
  end
end

# Equipment inventories
equipment_names = ['Sprayer Machine', 'Water Pump', 'Generator', 'Lawn Mower']
equipment_names.each do |name|
  Inventory.find_or_create_by!(name: name) do |inventory|
    inventory.stock_quantity = Faker::Number.between(from: 5, to: 15)
    inventory.category = equipment_category
    inventory.unit = piece_unit
    inventory.price = Faker::Number.decimal(l_digits: 4, r_digits: 2).to_f.clamp(800.0, 2500.0)
    inventory.supplier = Faker::Company.name
    inventory.input_date = Faker::Date.between(from: 365.days.ago, to: Date.today)
  end
end

puts "✓ Created #{Inventory.count} inventory items"

# Create Work Order Rates
puts 'Creating work order rates...'
day_unit = Unit.find_by(name: 'Day')
hectare_unit = Unit.find_by(name: 'Hectare')

# Day-based rates
day_based_work_orders = %w[Harvesting Spraying Fertilizing Weeding Pruning Planting]
day_based_work_orders.each do |work_order_name|
  WorkOrderRate.find_or_create_by!(work_order_name: work_order_name) do |rate|
    rate.rate = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(50.0, 100.0)
    rate.unit_id = day_unit.id.to_s
  end
end

# Hectare-based rates
hectare_based_work_orders = ['Land Preparation', 'Land Clearing', 'Irrigation Setup']
hectare_based_work_orders.each do |work_order_name|
  WorkOrderRate.find_or_create_by!(work_order_name: work_order_name) do |rate|
    rate.rate = Faker::Number.decimal(l_digits: 3, r_digits: 2).to_f.clamp(200.0, 400.0)
    rate.unit_id = hectare_unit.id.to_s
  end
end

puts "✓ Created #{WorkOrderRate.count} work order rates"

# Create Work Orders
puts 'Creating work orders...'
blocks = Block.all.to_a
work_order_rates = WorkOrderRate.all.to_a
conductor_user = User.find_by(email: 'conductor@example.com')
work_order_statuses = %w[ongoing pending amendment_required completed]

20.times do |i|
  WorkOrder.find_or_create_by!(id: i + 1) do |wo|
    wo.block_id = blocks.sample.id
    wo.work_order_rate_id = work_order_rates.sample.id
    wo.start_date = Faker::Date.between(from: 60.days.ago, to: Date.today)
    wo.work_order_status = work_order_statuses.sample
    wo.field_conductor_id = conductor_user.id
    wo.field_conductor_name = conductor_user.name

    # Add approval info for completed work orders
    if wo.work_order_status == 'completed'
      manager_user = User.find_by(email: 'manager@example.com')
      wo.approved_by = manager_user.id.to_s
      wo.approved_at = wo.start_date + rand(1..5).days
    end
  end
end

puts "✓ Created #{WorkOrder.count} work orders"

# Create Work Order Workers
puts 'Creating work order workers relationships...'
work_orders = WorkOrder.all.to_a
workers = Worker.limit(30).to_a # Use first 30 workers for work orders

work_orders.each do |work_order|
  # Assign 2-5 workers per work order
  assigned_workers = workers.sample(rand(2..5))

  assigned_workers.each do |worker|
    WorkOrderWorker.find_or_create_by!(work_order: work_order, worker: worker) do |wow|
      wow.worker_name = worker.name
      wow.rate = Faker::Number.decimal(l_digits: 2, r_digits: 2).to_f.clamp(50.0, 100.0)
      wow.amount = wow.rate * rand(3..8) # amount = rate * days worked
      wow.remarks = Faker::Lorem.sentence(word_count: 5)
    end
  end
end

puts "✓ Created #{WorkOrderWorker.count} work order workers relationships"

# Create Work Order Items
puts 'Creating work order items...'
inventories = Inventory.all.to_a

work_orders.each do |work_order|
  # Assign 1-3 inventory items per work order
  assigned_inventories = inventories.sample(rand(1..3))

  assigned_inventories.each do |inventory|
    WorkOrderItem.find_or_create_by!(work_order: work_order, inventory: inventory) do |item|
      item.item_name = inventory.name
      item.amount_used = rand(5..100)
      item.price = inventory.price
      item.unit_name = inventory.unit.name
      item.category_name = inventory.category.name
    end
  end
end

puts "✓ Created #{WorkOrderItem.count} work order items"

# Create Pay Calculations
puts 'Creating pay calculations...'
pay_calc = PayCalculation.find_or_create_by!(month_year: '2024-10') do |pc|
  pc.overall_total = 0
end

# Create Pay Calculation Details
puts 'Creating pay calculation details...'
Worker.where(is_active: true).limit(30).each do |worker|
  PayCalculationDetail.find_or_create_by!(pay_calculation: pay_calc, worker: worker) do |detail|
    gross = Faker::Number.decimal(l_digits: 4, r_digits: 2).to_f.clamp(3000.0, 10_000.0)
    deduct = Faker::Number.decimal(l_digits: 3, r_digits: 2).to_f.clamp(500.0, 2500.0)
    detail.gross_salary = gross
    detail.deductions = deduct
    detail.net_salary = gross - deduct
  end
end

# Update overall total
pay_calc.update!(overall_total: pay_calc.pay_calculation_details.sum(:gross_salary))

puts "✓ Created pay calculation with #{PayCalculationDetail.count} details"

puts "\n🎉 Seeding completed successfully!"
puts "\n📊 Summary:"
puts "  Users: #{User.count}"
puts "  Roles: #{Role.count}"
puts "  Permissions: #{Permission.count}"
puts "  Workers: #{Worker.count}"
puts "  Blocks: #{Block.count}"
puts "  Vehicles: #{Vehicle.count}"
puts "  Units: #{Unit.count}"
puts "  Categories: #{Category.count}"
puts "  Inventories: #{Inventory.count}"
puts "  Work Order Rates: #{WorkOrderRate.count}"
puts "  Work Orders: #{WorkOrder.count}"
puts "  Work Order Workers: #{WorkOrderWorker.count}"
puts "  Work Order Items: #{WorkOrderItem.count}"
puts "  Pay Calculations: #{PayCalculation.count}"
puts "  Pay Calculation Details: #{PayCalculationDetail.count}"
puts "\n👤 Test Users:"
puts '  Superadmin: superadmin@example.com / password'
puts '  Manager: manager@example.com / password'
puts '  Field Conductor: conductor@example.com / password'
puts '  Clerk: clerk@example.com / password'

# Re-enable auditing after seeds
Audited.auditing_enabled = true
