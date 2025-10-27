# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting seed process..."

# Disable auditing during seeds to avoid YAML serialization issues
Audited.auditing_enabled = false

# Clean up existing data (in reverse order of dependencies)
puts "Cleaning up existing data..."
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
puts "Creating permissions..."

# Standard resource permissions (non-namespaced)
user_permissions = [
  { subject: 'User', action: 'index', description: 'View users list' },
  { subject: 'User', action: 'show', description: 'View user details' },
  { subject: 'User', action: 'create', description: 'Create new users' },
  { subject: 'User', action: 'update', description: 'Edit users' },
  { subject: 'User', action: 'destroy', description: 'Delete users' }
]

worker_permissions = [
  { subject: 'Worker', action: 'index', description: 'View workers list' },
  { subject: 'Worker', action: 'show', description: 'View worker details' },
  { subject: 'Worker', action: 'create', description: 'Add new workers' },
  { subject: 'Worker', action: 'update', description: 'Edit workers' },
  { subject: 'Worker', action: 'destroy', description: 'Remove workers' }
]

inventory_permissions = [
  { subject: 'Inventory', action: 'index', description: 'View inventories list' },
  { subject: 'Inventory', action: 'show', description: 'View inventory details' },
  { subject: 'Inventory', action: 'create', description: 'Create inventories' },
  { subject: 'Inventory', action: 'update', description: 'Edit inventories' },
  { subject: 'Inventory', action: 'destroy', description: 'Delete inventories' }
]

vehicle_permissions = [
  { subject: 'Vehicle', action: 'index', description: 'View vehicles list' },
  { subject: 'Vehicle', action: 'show', description: 'View vehicle details' },
  { subject: 'Vehicle', action: 'create', description: 'Register vehicles' },
  { subject: 'Vehicle', action: 'update', description: 'Update vehicles' },
  { subject: 'Vehicle', action: 'destroy', description: 'Deactivate vehicles' }
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

# Combine all permissions
all_permissions = [
  *user_permissions,
  *worker_permissions,
  *inventory_permissions,
  *vehicle_permissions,
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
puts "Creating roles..."

# Superadmin - bypasses all permission checks
superadmin_role = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access (bypasses all permission checks)'
end
# No need to assign permissions - superadmin bypasses permission checks

# Manager - can approve work orders and manage pay calculations
manager_role = Role.find_or_create_by!(name: 'Manager') do |role|
  role.description = 'Can approve work orders and manage pay calculations'
end
manager_permissions = Permission.where(subject: ['WorkOrder::Approval', 'WorkOrder::PayCalculation', 'Payslip'])
                                .or(Permission.where(subject: ['Worker', 'Vehicle', 'Inventory', 'User'], action: ['index', 'show']))
manager_role.permissions = manager_permissions

# Field Conductor - can create and manage work orders
field_conductor_role = Role.find_or_create_by!(name: 'Field Conductor') do |role|
  role.description = 'Can create and manage work orders'
end
field_conductor_permissions = Permission.where(subject: 'WorkOrder::Detail', action: ['index', 'show', 'create', 'update'])
                                        .or(Permission.where(subject: ['Worker', 'Vehicle', 'Inventory'], action: ['index', 'show']))
field_conductor_role.permissions = field_conductor_permissions

# Clerk - administrative support with read/write access to master data
clerk_role = Role.find_or_create_by!(name: 'Clerk') do |role|
  role.description = 'Can manage master data (users, workers, vehicles, inventories)'
end
clerk_permissions = Permission.where(subject: ['User', 'Worker', 'Vehicle', 'Inventory'])
clerk_role.permissions = clerk_permissions

puts "✓ Created #{Role.count} roles"

# Create Users
puts "Creating users..."

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
puts "Creating units..."
units_data = [
  { name: 'Kg', unit_type: 'Weight' },
  { name: 'Liter', unit_type: 'Volume' },
  { name: 'Piece', unit_type: 'Count' },
  { name: 'Hour', unit_type: 'Time' },
  { name: 'Day', unit_type: 'Time' },
  { name: 'Hectare', unit_type: 'Area' },
  { name: 'Ton', unit_type: 'Weight' },
]

units_data.each do |unit_data|
  Unit.find_or_create_by!(unit_data)
end
puts "✓ Created #{Unit.count} units"

# Create Categories
puts "Creating categories..."
material_category = Category.find_or_create_by!(name: 'Materials', category_type: 'Inventory')
fertilizer_category = Category.find_or_create_by!(name: 'Fertilizers', category_type: 'Inventory', parent: material_category)
pesticide_category = Category.find_or_create_by!(name: 'Pesticides', category_type: 'Inventory', parent: material_category)
tools_category = Category.find_or_create_by!(name: 'Tools', category_type: 'Inventory')
equipment_category = Category.find_or_create_by!(name: 'Equipment', category_type: 'Inventory')

puts "✓ Created #{Category.count} categories"

# Create Blocks
puts "Creating blocks..."
blocks_data = [
  { block_number: 'BLK-001', hectarage: 10.5 },
  { block_number: 'BLK-002', hectarage: 15.0 },
  { block_number: 'BLK-003', hectarage: 8.25 },
  { block_number: 'BLK-004', hectarage: 12.75 },
  { block_number: 'BLK-005', hectarage: 20.0 },
]

blocks_data.each do |block_data|
  Block.find_or_create_by!(block_data)
end
puts "✓ Created #{Block.count} blocks"

# Create Vehicles
puts "Creating vehicles..."
vehicles_data = [
  { vehicle_number: 'VH-001', vehicle_model: 'Toyota Hilux' },
  { vehicle_number: 'VH-002', vehicle_model: 'Isuzu D-Max' },
  { vehicle_number: 'VH-003', vehicle_model: 'Mitsubishi Triton' },
]

vehicles_data.each do |vehicle_data|
  Vehicle.find_or_create_by!(vehicle_data)
end
puts "✓ Created #{Vehicle.count} vehicles"

# Create Workers
puts "Creating workers..."
workers_data = [
  { name: 'John Doe', worker_type: 'Harvester', gender: 'Male', is_active: true, hired_date: Date.new(2023, 1, 15), nationality: 'Indonesian', identity_number: 'ID-001' },
  { name: 'Jane Smith', worker_type: 'Sprayer', gender: 'Female', is_active: true, hired_date: Date.new(2023, 2, 20), nationality: 'Indonesian', identity_number: 'ID-002' },
  { name: 'Ahmad Rahman', worker_type: 'Harvester', gender: 'Male', is_active: true, hired_date: Date.new(2023, 3, 10), nationality: 'Indonesian', identity_number: 'ID-003' },
  { name: 'Siti Nurhaliza', worker_type: 'Fertilizer', gender: 'Female', is_active: true, hired_date: Date.new(2023, 4, 5), nationality: 'Indonesian', identity_number: 'ID-004' },
  { name: 'Budi Santoso', worker_type: 'Harvester', gender: 'Male', is_active: true, hired_date: Date.new(2023, 5, 12), nationality: 'Indonesian', identity_number: 'ID-005' },
  { name: 'Maria Garcia', worker_type: 'Sprayer', gender: 'Female', is_active: false, hired_date: Date.new(2022, 8, 20), nationality: 'Filipino', identity_number: 'ID-006' },
]

workers_data.each do |worker_data|
  Worker.find_or_create_by!(identity_number: worker_data[:identity_number]) do |worker|
    worker.assign_attributes(worker_data)
  end
end
puts "✓ Created #{Worker.count} workers"

# Create Inventories
puts "Creating inventories..."
kg_unit = Unit.find_by(name: 'Kg')
liter_unit = Unit.find_by(name: 'Liter')
piece_unit = Unit.find_by(name: 'Piece')

inventories_data = [
  { name: 'NPK Fertilizer', stock_quantity: 450, category: fertilizer_category, unit: kg_unit, price: 65.00, supplier: 'Agro Supplier Co.', input_date: Date.today - 30 },
  { name: 'Organic Fertilizer', stock_quantity: 280, category: fertilizer_category, unit: kg_unit, price: 55.00, supplier: 'Green Farm Supplies', input_date: Date.today - 25 },
  { name: 'Herbicide', stock_quantity: 85, category: pesticide_category, unit: liter_unit, price: 38.50, supplier: 'ChemAgro Ltd.', input_date: Date.today - 20 },
  { name: 'Insecticide', stock_quantity: 130, category: pesticide_category, unit: liter_unit, price: 42.00, supplier: 'ChemAgro Ltd.', input_date: Date.today - 15 },
  { name: 'Harvesting Knife', stock_quantity: 48, category: tools_category, unit: piece_unit, price: 28.50, supplier: 'Tool Master', input_date: Date.today - 60 },
  { name: 'Sprayer Machine', stock_quantity: 8, category: equipment_category, unit: piece_unit, price: 1250.00, supplier: 'Agro Equipment Inc.', input_date: Date.today - 90 },
]

inventories_data.each do |inventory_data|
  Inventory.find_or_create_by!(name: inventory_data[:name]) do |inventory|
    inventory.assign_attributes(inventory_data)
  end
end
puts "✓ Created #{Inventory.count} inventory items"

# Create Work Order Rates
puts "Creating work order rates..."
hour_unit = Unit.find_by(name: 'Hour')
day_unit = Unit.find_by(name: 'Day')
hectare_unit = Unit.find_by(name: 'Hectare')

rates_data = [
  { work_order_name: 'Harvesting', rate: 85.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Spraying', rate: 75.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Fertilizing', rate: 65.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Weeding', rate: 55.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Land Preparation', rate: 250.00, unit_id: hectare_unit.id.to_s },
]

rates_data.each do |rate_data|
  WorkOrderRate.find_or_create_by!(work_order_name: rate_data[:work_order_name]) do |rate|
    rate.assign_attributes(rate_data)
  end
end
puts "✓ Created #{WorkOrderRate.count} work order rates"

# Create Work Orders
puts "Creating work orders..."
block1 = Block.find_by(block_number: 'BLK-001')
block2 = Block.find_by(block_number: 'BLK-002')
harvesting_rate = WorkOrderRate.find_by(work_order_name: 'Harvesting')
spraying_rate = WorkOrderRate.find_by(work_order_name: 'Spraying')
conductor_user = User.find_by(email: 'conductor@example.com')

work_order1 = WorkOrder.find_or_create_by!(id: 1) do |wo|
  wo.block_id = block1.id
  wo.work_order_rate_id = harvesting_rate.id
  wo.start_date = Date.today - 7
  wo.work_order_status = 'ongoing'
  wo.field_conductor_id = conductor_user.id
  wo.field_conductor_name = conductor_user.name
  wo.approved_by = nil
  wo.approved_at = nil
end

work_order2 = WorkOrder.find_or_create_by!(id: 2) do |wo|
  wo.block_id = block2.id
  wo.work_order_rate_id = spraying_rate.id
  wo.start_date = Date.today - 3
  wo.work_order_status = 'pending'
  wo.field_conductor_id = conductor_user.id
  wo.field_conductor_name = conductor_user.name
end

puts "✓ Created #{WorkOrder.count} work orders"

# Create Work Order Workers
puts "Creating work order workers relationships..."
worker1 = Worker.find_by(identity_number: 'ID-001')
worker2 = Worker.find_by(identity_number: 'ID-002')
worker3 = Worker.find_by(identity_number: 'ID-003')

WorkOrderWorker.find_or_create_by!(work_order: work_order1, worker: worker1) do |wow|
  wow.worker_name = worker1.name
  wow.rate = 85.00
  wow.amount = 425.00
  wow.remarks = 'Harvesting work on Block 1'
end

WorkOrderWorker.find_or_create_by!(work_order: work_order1, worker: worker2) do |wow|
  wow.worker_name = worker2.name
  wow.rate = 75.00
  wow.amount = 225.00
  wow.remarks = 'Spraying pesticides'
end

WorkOrderWorker.find_or_create_by!(work_order: work_order2, worker: worker3) do |wow|
  wow.worker_name = worker3.name
  wow.rate = 85.00
  wow.amount = 340.00
  wow.remarks = 'Harvesting work on Block 2'
end

puts "✓ Created #{WorkOrderWorker.count} work order workers relationships"

# Create Work Order Items
puts "Creating work order items..."
fertilizer = Inventory.find_by(name: 'NPK Fertilizer')
herbicide = Inventory.find_by(name: 'Herbicide')

WorkOrderItem.find_or_create_by!(work_order: work_order1, inventory: fertilizer) do |item|
  item.item_name = fertilizer.name
  item.amount_used = 50
  item.price = fertilizer.price
  item.unit_name = fertilizer.unit.name
  item.category_name = fertilizer.category.name
end

WorkOrderItem.find_or_create_by!(work_order: work_order2, inventory: herbicide) do |item|
  item.item_name = herbicide.name
  item.amount_used = 10
  item.price = herbicide.price
  item.unit_name = herbicide.unit.name
  item.category_name = herbicide.category.name
end

puts "✓ Created #{WorkOrderItem.count} work order items"

# Create Pay Calculations
puts "Creating pay calculations..."
pay_calc = PayCalculation.find_or_create_by!(month_year: '2024-10') do |pc|
  pc.overall_total = 0
end

# Create Pay Calculation Details
puts "Creating pay calculation details..."
[worker1, worker2, worker3].each do |worker|
  PayCalculationDetail.find_or_create_by!(pay_calculation: pay_calc, worker: worker) do |detail|
    gross = rand(3000..8000).to_f
    deduct = rand(500..2000).to_f
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
puts "  Superadmin: superadmin@example.com / password"
puts "  Manager: manager@example.com / password"
puts "  Field Conductor: conductor@example.com / password"
puts "  Clerk: clerk@example.com / password"

# Re-enable auditing after seeds
Audited.auditing_enabled = true
