# frozen_string_literal: true

# Production Seeds - Complete data without Faker
# Usage: SEED_ENV=production rails db:seed

puts '🌱 Starting production seed process...'

# Disable auditing during seeds
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
load Rails.root.join('db', 'seeds', 'permissions.rb')
puts "✓ Created #{Permission.count} permissions"

# Create Roles
puts 'Creating roles...'

superadmin_role = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access (bypasses all permission checks)'
end
# Superadmin gets all permissions
superadmin_role.permissions = Permission.all

manager_role = Role.find_or_create_by!(name: 'Manager') do |role|
  role.description = 'Can view dashboard and approve work orders'
end
manager_permission_codes = [
  'dashboard.index',
  'work_orders.approvals.index',
  'work_orders.approvals.show',
  'work_orders.approvals.update',
  'work_orders.approvals.approve',
  'work_orders.approvals.request_amendment'
]
manager_role.permissions = Permission.where(code: manager_permission_codes)

field_conductor_role = Role.find_or_create_by!(name: 'Field Conductor') do |role|
  role.description = 'Can create and manage work order details'
end
field_conductor_permission_codes = [
  'work_orders.details.index',
  'work_orders.details.show',
  'work_orders.details.new',
  'work_orders.details.create',
  'work_orders.details.edit',
  'work_orders.details.update',
  'work_orders.details.destroy',
  'work_orders.details.mark_complete'
]
field_conductor_role.permissions = Permission.where(code: field_conductor_permission_codes)

clerk_role = Role.find_or_create_by!(name: 'Clerk') do |role|
  role.description = 'Can manage pay calculations, payslips, inventories, workers, and master data'
end
clerk_permission_codes = [
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
clerk_role.permissions = Permission.where(code: clerk_permission_codes)

puts "✓ Created #{Role.count} roles"

# Create Users
puts 'Creating users...'

# Superadmin user
User.find_or_create_by!(email: 'superadmin@example.com') do |user|
  user.name = 'Super Admin'
  user.password = 'ChangeMe123!'
  user.password_confirmation = 'ChangeMe123!'
  user.role = superadmin_role
end

# Manager user
User.find_or_create_by!(email: 'manager@example.com') do |user|
  user.name = 'Manager User'
  user.password = 'ChangeMe123!'
  user.password_confirmation = 'ChangeMe123!'
  user.role = manager_role
end

# Field Conductor user
User.find_or_create_by!(email: 'conductor@example.com') do |user|
  user.name = 'Field Conductor'
  user.password = 'ChangeMe123!'
  user.password_confirmation = 'ChangeMe123!'
  user.role = field_conductor_role
end

# Clerk user
User.find_or_create_by!(email: 'clerk@example.com') do |user|
  user.name = 'Clerk User'
  user.password = 'ChangeMe123!'
  user.password_confirmation = 'ChangeMe123!'
  user.role = clerk_role
end

puts "✓ Created #{User.count} users"

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
material_category = Category.find_or_create_by!(name: 'Materials', category_type: 'Inventory')
fertilizer_category = Category.find_or_create_by!(name: 'Fertilizers', category_type: 'Inventory',
                                                  parent: material_category)
pesticide_category = Category.find_or_create_by!(name: 'Pesticides', category_type: 'Inventory',
                                                 parent: material_category)
tools_category = Category.find_or_create_by!(name: 'Tools', category_type: 'Inventory')
equipment_category = Category.find_or_create_by!(name: 'Equipment', category_type: 'Inventory')

puts "✓ Created #{Category.count} categories"

# Load Deduction Types
puts 'Loading deduction types...'
load Rails.root.join('db', 'seeds', 'deduction_types.rb')

# Create Blocks
puts 'Creating blocks...'
blocks_data = [
  { block_number: 'BLK-001', hectarage: 15.50 },
  { block_number: 'BLK-002', hectarage: 22.30 },
  { block_number: 'BLK-003', hectarage: 18.75 },
  { block_number: 'BLK-004', hectarage: 30.00 },
  { block_number: 'BLK-005', hectarage: 12.40 },
  { block_number: 'BLK-006', hectarage: 25.60 },
  { block_number: 'BLK-007', hectarage: 19.80 },
  { block_number: 'BLK-008', hectarage: 28.90 },
  { block_number: 'BLK-009', hectarage: 16.20 },
  { block_number: 'BLK-010', hectarage: 21.50 }
]

blocks_data.each do |data|
  Block.find_or_create_by!(block_number: data[:block_number]) do |block|
    block.hectarage = data[:hectarage]
  end
end
puts "✓ Created #{Block.count} blocks"

# Create Vehicles
puts 'Creating vehicles...'
vehicles_data = [
  { vehicle_number: 'VH-001', vehicle_model: 'Toyota Hilux' },
  { vehicle_number: 'VH-002', vehicle_model: 'Isuzu D-Max' },
  { vehicle_number: 'VH-003', vehicle_model: 'Mitsubishi Triton' },
  { vehicle_number: 'VH-004', vehicle_model: 'Ford Ranger' },
  { vehicle_number: 'VH-005', vehicle_model: 'Nissan Navara' },
  { vehicle_number: 'VH-006', vehicle_model: 'Mazda BT-50' },
  { vehicle_number: 'VH-007', vehicle_model: 'Chevrolet Colorado' },
  { vehicle_number: 'VH-008', vehicle_model: 'Toyota Hilux' },
  { vehicle_number: 'VH-009', vehicle_model: 'Isuzu D-Max' },
  { vehicle_number: 'VH-010', vehicle_model: 'Mitsubishi Triton' }
]

vehicles_data.each do |data|
  Vehicle.find_or_create_by!(vehicle_number: data[:vehicle_number]) do |vehicle|
    vehicle.vehicle_model = data[:vehicle_model]
  end
end
puts "✓ Created #{Vehicle.count} vehicles"

# Create Workers
puts 'Creating workers...'
workers_data = [
  { identity_number: 'ID-001', name: 'Ahmad Yani', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-01-15', nationality: 'Indonesian' },
  { identity_number: 'ID-002', name: 'Siti Nurhaliza', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-03-10', nationality: 'Indonesian' },
  { identity_number: 'ID-003', name: 'Budi Santoso', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2021-05-20', nationality: 'Indonesian' },
  { identity_number: 'ID-004', name: 'Dewi Lestari', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2019-08-12', nationality: 'Indonesian' },
  { identity_number: 'ID-005', name: 'Eko Prasetyo', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2022-02-05', nationality: 'Indonesian' },
  { identity_number: 'ID-006', name: 'Fitri Handayani', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-11-22', nationality: 'Indonesian' },
  { identity_number: 'ID-007', name: 'Gunawan Wijaya', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2018-06-30', nationality: 'Indonesian' },
  { identity_number: 'ID-008', name: 'Hani Kartika', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2023-01-18', nationality: 'Indonesian' },
  { identity_number: 'ID-009', name: 'Irfan Hakim', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2019-04-25', nationality: 'Indonesian' },
  { identity_number: 'ID-010', name: 'Jasmine Putri', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2021-09-14', nationality: 'Indonesian' },
  { identity_number: 'ID-011', name: 'Kurniawan', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-07-08', nationality: 'Indonesian' },
  { identity_number: 'ID-012', name: 'Linda Sari', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2019-12-03', nationality: 'Indonesian' },
  { identity_number: 'ID-013', name: 'Muhammad Ali', worker_type: 'Part - Time', gender: 'Male', is_active: true,
    hired_date: '2022-05-16', nationality: 'Indonesian' },
  { identity_number: 'ID-014', name: 'Nur Azizah', worker_type: 'Full - Time', gender: 'Female', is_active: false,
    hired_date: '2018-10-20', nationality: 'Indonesian' },
  { identity_number: 'ID-015', name: 'Oscar Pratama', worker_type: 'Part - Time', gender: 'Male', is_active: true,
    hired_date: '2023-03-12', nationality: 'Indonesian' },
  { identity_number: 'ID-016', name: 'Putri Indah', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2021-01-28', nationality: 'Indonesian' },
  { identity_number: 'ID-017', name: 'Rahmat Hidayat', worker_type: 'Full - Time', gender: 'Male', is_active: true,
    hired_date: '2020-04-15', nationality: 'Indonesian' },
  { identity_number: 'ID-018', name: 'Sri Rahayu', worker_type: 'Part - Time', gender: 'Female', is_active: true,
    hired_date: '2022-08-22', nationality: 'Indonesian' },
  { identity_number: 'ID-019', name: 'Taufik Rahman', worker_type: 'Full - Time', gender: 'Male', is_active: true,
    hired_date: '2019-02-14', nationality: 'Indonesian' },
  { identity_number: 'ID-020', name: 'Umi Kalsum', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2020-09-05', nationality: 'Indonesian' },
  { identity_number: 'ID-021', name: 'Vino Bastian', worker_type: 'Part - Time', gender: 'Male', is_active: false,
    hired_date: '2021-11-30', nationality: 'Indonesian' },
  { identity_number: 'ID-022', name: 'Wulan Guritno', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2018-05-18', nationality: 'Indonesian' },
  { identity_number: 'ID-023', name: 'Yudi Setiawan', worker_type: 'Full - Time', gender: 'Male', is_active: true,
    hired_date: '2020-12-08', nationality: 'Indonesian' },
  { identity_number: 'ID-024', name: 'Zahra Amelia', worker_type: 'Part - Time', gender: 'Female', is_active: true,
    hired_date: '2022-03-25', nationality: 'Indonesian' },
  { identity_number: 'ID-025', name: 'Agus Salim', worker_type: 'Full - Time', gender: 'Male', is_active: true,
    hired_date: '2019-07-10', nationality: 'Indonesian' },
  { identity_number: 'ID-026', name: 'Bella Saphira', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2021-04-02', nationality: 'Indonesian' },
  { identity_number: 'ID-027', name: 'Chandra Putra', worker_type: 'Part - Time', gender: 'Male', is_active: true,
    hired_date: '2023-02-14', nationality: 'Indonesian' },
  { identity_number: 'ID-028', name: 'Diana Pungky', worker_type: 'Full - Time', gender: 'Female', is_active: false,
    hired_date: '2018-09-22', nationality: 'Indonesian' },
  { identity_number: 'ID-029', name: 'Erwin Prasetya', worker_type: 'Part - Time', gender: 'Male', is_active: true,
    hired_date: '2022-06-18', nationality: 'Indonesian' },
  { identity_number: 'ID-030', name: 'Farah Quinn', worker_type: 'Full - Time', gender: 'Female', is_active: true,
    hired_date: '2020-10-25', nationality: 'Indonesian' }
]

workers_data.each do |data|
  Worker.find_or_create_by!(identity_number: data[:identity_number]) do |worker|
    worker.name = data[:name]
    worker.worker_type = data[:worker_type]
    worker.gender = data[:gender]
    worker.is_active = data[:is_active]
    worker.hired_date = Date.parse(data[:hired_date])
    # Normalize various country strings to the allowed Worker nationalities
    worker.nationality = (data[:nationality] == 'Malaysian' ? 'Local' : 'Foreigner')
  end
end
puts "✓ Created #{Worker.count} workers"

# Create Inventories
puts 'Creating inventories...'
kg_unit = Unit.find_by(name: 'Kg')
liter_unit = Unit.find_by(name: 'Liter')
piece_unit = Unit.find_by(name: 'Piece')

# Fertilizer inventories
fertilizer_data = [
  { name: 'NPK Fertilizer', stock_quantity: 250, category: fertilizer_category, unit: kg_unit, price: 65.00,
    supplier: 'PT Pupuk Indonesia' },
  { name: 'Organic Fertilizer', stock_quantity: 180, category: fertilizer_category, unit: kg_unit, price: 55.00,
    supplier: 'CV Organik Jaya' },
  { name: 'Urea Fertilizer', stock_quantity: 320, category: fertilizer_category, unit: kg_unit, price: 70.00,
    supplier: 'PT Pupuk Indonesia' },
  { name: 'Compost', stock_quantity: 150, category: fertilizer_category, unit: kg_unit, price: 45.00,
    supplier: 'CV Organik Jaya' },
  { name: 'Phosphate Fertilizer', stock_quantity: 200, category: fertilizer_category, unit: kg_unit, price: 75.00,
    supplier: 'PT Pupuk Indonesia' }
]

fertilizer_data.each_with_index do |data, _index|
  Inventory.find_or_create_by!(name: data[:name]) do |inventory|
    inventory.stock_quantity = data[:stock_quantity]
    inventory.category = data[:category]
    inventory.unit = data[:unit]
    inventory.price = data[:price]
    inventory.supplier = data[:supplier]
    inventory.input_date = Date.new(2024, 1, 1) - 60.days
  end
end

# Pesticide inventories
pesticide_data = [
  { name: 'Herbicide', stock_quantity: 120, category: pesticide_category, unit: liter_unit, price: 45.00,
    supplier: 'PT Agro Kimia' },
  { name: 'Insecticide', stock_quantity: 95, category: pesticide_category, unit: liter_unit, price: 50.00,
    supplier: 'PT Agro Kimia' },
  { name: 'Fungicide', stock_quantity: 110, category: pesticide_category, unit: liter_unit, price: 48.00,
    supplier: 'CV Pestisida Nusantara' },
  { name: 'Pesticide Mix', stock_quantity: 85, category: pesticide_category, unit: liter_unit, price: 55.00,
    supplier: 'PT Agro Kimia' }
]

pesticide_data.each_with_index do |data, _index|
  Inventory.find_or_create_by!(name: data[:name]) do |inventory|
    inventory.stock_quantity = data[:stock_quantity]
    inventory.category = data[:category]
    inventory.unit = data[:unit]
    inventory.price = data[:price]
    inventory.supplier = data[:supplier]
    inventory.input_date = Date.new(2024, 1, 1) - 60.days
  end
end

# Tools inventories
tool_data = [
  { name: 'Harvesting Knife', stock_quantity: 50, category: tools_category, unit: piece_unit, price: 25.00,
    supplier: 'Toko Alat Tani' },
  { name: 'Pruning Shears', stock_quantity: 40, category: tools_category, unit: piece_unit, price: 35.00,
    supplier: 'Toko Alat Tani' },
  { name: 'Hand Trowel', stock_quantity: 60, category: tools_category, unit: piece_unit, price: 18.00,
    supplier: 'CV Perkakas Pertanian' },
  { name: 'Garden Hoe', stock_quantity: 45, category: tools_category, unit: piece_unit, price: 30.00,
    supplier: 'Toko Alat Tani' },
  { name: 'Machete', stock_quantity: 35, category: tools_category, unit: piece_unit, price: 40.00,
    supplier: 'CV Perkakas Pertanian' }
]

tool_data.each_with_index do |data, _index|
  Inventory.find_or_create_by!(name: data[:name]) do |inventory|
    inventory.stock_quantity = data[:stock_quantity]
    inventory.category = data[:category]
    inventory.unit = data[:unit]
    inventory.price = data[:price]
    inventory.supplier = data[:supplier]
    inventory.input_date = Date.new(2024, 1, 1) - 135.days
  end
end

# Equipment inventories
equipment_data = [
  { name: 'Sprayer Machine', stock_quantity: 8, category: equipment_category, unit: piece_unit, price: 1500.00,
    supplier: 'PT Mesin Pertanian' },
  { name: 'Water Pump', stock_quantity: 6, category: equipment_category, unit: piece_unit, price: 1200.00,
    supplier: 'CV Teknik Jaya' },
  { name: 'Generator', stock_quantity: 5, category: equipment_category, unit: piece_unit, price: 2000.00,
    supplier: 'PT Mesin Pertanian' },
  { name: 'Lawn Mower', stock_quantity: 7, category: equipment_category, unit: piece_unit, price: 1800.00,
    supplier: 'CV Teknik Jaya' }
]

equipment_data.each_with_index do |data, _index|
  Inventory.find_or_create_by!(name: data[:name]) do |inventory|
    inventory.stock_quantity = data[:stock_quantity]
    inventory.category = data[:category]
    inventory.unit = data[:unit]
    inventory.price = data[:price]
    inventory.supplier = data[:supplier]
    inventory.input_date = Date.new(2024, 1, 1) - 270.days
  end
end

puts "✓ Created #{Inventory.count} inventory items"

# Create Work Order Rates
puts 'Creating work order rates...'
day_unit = Unit.find_by(name: 'Day')
hectare_unit = Unit.find_by(name: 'Hectare')

# Day-based rates
day_based_rates = [
  { work_order_name: 'Harvesting', rate: 75.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Spraying', rate: 65.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Fertilizing', rate: 70.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Weeding', rate: 60.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Pruning', rate: 80.00, unit_id: day_unit.id.to_s },
  { work_order_name: 'Planting', rate: 85.00, unit_id: day_unit.id.to_s }
]

day_based_rates.each do |data|
  WorkOrderRate.find_or_create_by!(work_order_name: data[:work_order_name]) do |rate|
    rate.rate = data[:rate]
    rate.unit_id = data[:unit_id]
  end
end

# Hectare-based rates
hectare_based_rates = [
  { work_order_name: 'Land Preparation', rate: 300.00, unit_id: hectare_unit.id.to_s },
  { work_order_name: 'Land Clearing', rate: 250.00, unit_id: hectare_unit.id.to_s },
  { work_order_name: 'Irrigation Setup', rate: 350.00, unit_id: hectare_unit.id.to_s }
]

hectare_based_rates.each do |data|
  WorkOrderRate.find_or_create_by!(work_order_name: data[:work_order_name]) do |rate|
    rate.rate = data[:rate]
    rate.unit_id = data[:unit_id]
  end
end

puts "✓ Created #{WorkOrderRate.count} work order rates"

# Create Work Orders
puts 'Creating work orders...'
blocks = Block.all.to_a
work_order_rates = WorkOrderRate.all.to_a
conductor_user = User.find_by(email: 'conductor@example.com')
manager_user = User.find_by(email: 'manager@example.com')

work_orders_data = [
  { block: blocks[0], work_order_rate: work_order_rates[0], start_date: Date.new(2024, 10, 1),
    work_order_status: 'completed' },
  { block: blocks[1], work_order_rate: work_order_rates[1], start_date: Date.new(2024, 10, 6),
    work_order_status: 'completed' },
  { block: blocks[2], work_order_rate: work_order_rates[2], start_date: Date.new(2024, 10, 11),
    work_order_status: 'ongoing' },
  { block: blocks[3], work_order_rate: work_order_rates[3], start_date: Date.new(2024, 10, 16),
    work_order_status: 'pending' },
  { block: blocks[4], work_order_rate: work_order_rates[4], start_date: Date.new(2024, 10, 21),
    work_order_status: 'completed' },
  { block: blocks[5], work_order_rate: work_order_rates[5], start_date: Date.new(2024, 10, 26),
    work_order_status: 'ongoing' },
  { block: blocks[6], work_order_rate: work_order_rates[0], start_date: Date.new(2024, 11, 1),
    work_order_status: 'amendment_required' },
  { block: blocks[7], work_order_rate: work_order_rates[1], start_date: Date.new(2024, 11, 6),
    work_order_status: 'pending' },
  { block: blocks[8], work_order_rate: work_order_rates[2], start_date: Date.new(2024, 11, 11),
    work_order_status: 'ongoing' },
  { block: blocks[9], work_order_rate: work_order_rates[3], start_date: Date.new(2024, 11, 14),
    work_order_status: 'pending' }
]

work_orders_data.each do |data|
  WorkOrder.find_or_create_by!(block_id: data[:block].id, start_date: data[:start_date]) do |wo|
    wo.work_order_rate_id = data[:work_order_rate].id
    wo.work_order_status = data[:work_order_status]
    wo.field_conductor_id = conductor_user.id
    wo.field_conductor_name = conductor_user.name

    # Add approval info for completed work orders
    if wo.work_order_status == 'completed'
      wo.approved_by = manager_user.id.to_s
      wo.approved_at = wo.start_date + 5.days
    end
  end
end

puts "✓ Created #{WorkOrder.count} work orders"

# Create Work Order Workers
puts 'Creating work order workers relationships...'
work_orders = WorkOrder.all.to_a
workers = Worker.where(is_active: true).limit(20).to_a

work_order_workers_data = [
  # Work Order 1 - 3 workers
  { work_order: work_orders[0], worker: workers[0], rate: 75.00, days: 5 },
  { work_order: work_orders[0], worker: workers[1], rate: 75.00, days: 5 },
  { work_order: work_orders[0], worker: workers[2], rate: 75.00, days: 4 },

  # Work Order 2 - 4 workers
  { work_order: work_orders[1], worker: workers[3], rate: 65.00, days: 6 },
  { work_order: work_orders[1], worker: workers[4], rate: 65.00, days: 6 },
  { work_order: work_orders[1], worker: workers[5], rate: 65.00, days: 5 },
  { work_order: work_orders[1], worker: workers[6], rate: 65.00, days: 5 },

  # Work Order 3 - 3 workers
  { work_order: work_orders[2], worker: workers[7], rate: 70.00, days: 4 },
  { work_order: work_orders[2], worker: workers[8], rate: 70.00, days: 4 },
  { work_order: work_orders[2], worker: workers[9], rate: 70.00, days: 3 },

  # Work Order 4 - 2 workers
  { work_order: work_orders[3], worker: workers[10], rate: 60.00, days: 5 },
  { work_order: work_orders[3], worker: workers[11], rate: 60.00, days: 5 },

  # Work Order 5 - 4 workers
  { work_order: work_orders[4], worker: workers[12], rate: 80.00, days: 6 },
  { work_order: work_orders[4], worker: workers[13], rate: 80.00, days: 6 },
  { work_order: work_orders[4], worker: workers[14], rate: 80.00, days: 5 },
  { work_order: work_orders[4], worker: workers[15], rate: 80.00, days: 5 },

  # Work Order 6 - 3 workers
  { work_order: work_orders[5], worker: workers[16], rate: 85.00, days: 4 },
  { work_order: work_orders[5], worker: workers[17], rate: 85.00, days: 4 },
  { work_order: work_orders[5], worker: workers[18], rate: 85.00, days: 3 }
]

work_order_workers_data.each do |data|
  WorkOrderWorker.find_or_create_by!(work_order: data[:work_order], worker: data[:worker]) do |wow|
    wow.worker_name = data[:worker].name
    wow.rate = data[:rate]
    wow.amount = data[:rate] * data[:days]
    wow.remarks = "#{data[:days]} days worked"
  end
end

puts "✓ Created #{WorkOrderWorker.count} work order workers relationships"

# Create Work Order Items
puts 'Creating work order items...'
inventories = Inventory.includes(:unit, :category).to_a

work_order_items_data = [
  # Work Order 1 items
  { work_order: work_orders[0], inventory: inventories[0], amount_used: 50 },
  { work_order: work_orders[0], inventory: inventories[9], amount_used: 10 },

  # Work Order 2 items
  { work_order: work_orders[1], inventory: inventories[5], amount_used: 30 },
  { work_order: work_orders[1], inventory: inventories[13], amount_used: 5 },

  # Work Order 3 items
  { work_order: work_orders[2], inventory: inventories[1], amount_used: 40 },
  { work_order: work_orders[2], inventory: inventories[10], amount_used: 8 },
  { work_order: work_orders[2], inventory: inventories[14], amount_used: 3 },

  # Work Order 4 items
  { work_order: work_orders[3], inventory: inventories[11], amount_used: 6 },

  # Work Order 5 items
  { work_order: work_orders[4], inventory: inventories[2], amount_used: 45 },
  { work_order: work_orders[4], inventory: inventories[12], amount_used: 7 }
]

work_order_items_data.each do |data|
  WorkOrderItem.find_or_create_by!(work_order: data[:work_order], inventory: data[:inventory]) do |item|
    item.item_name = data[:inventory].name
    item.amount_used = data[:amount_used]
    item.price = data[:inventory].price
    item.unit_name = data[:inventory].unit.name
    item.category_name = data[:inventory].category.name
  end
end

puts "✓ Created #{WorkOrderItem.count} work order items"

# Create Pay Calculations
puts 'Creating pay calculations...'
# Use PayCalculation API compatible with current model
pay_calc = PayCalculation.find_or_create_for_month('2024-11')

# Create Pay Calculation Details
puts 'Creating pay calculation details...'
pay_calc_details_data = [
  { worker: workers[0], gross_salary: 4500.00, deductions: 450.00 },
  { worker: workers[1], gross_salary: 5200.00, deductions: 520.00 },
  { worker: workers[2], gross_salary: 3800.00, deductions: 380.00 },
  { worker: workers[3], gross_salary: 6100.00, deductions: 610.00 },
  { worker: workers[4], gross_salary: 4800.00, deductions: 480.00 },
  { worker: workers[5], gross_salary: 5500.00, deductions: 550.00 },
  { worker: workers[6], gross_salary: 4200.00, deductions: 420.00 },
  { worker: workers[7], gross_salary: 5800.00, deductions: 580.00 },
  { worker: workers[8], gross_salary: 4600.00, deductions: 460.00 },
  { worker: workers[9], gross_salary: 5300.00, deductions: 530.00 },
  { worker: workers[10], gross_salary: 3900.00, deductions: 390.00 },
  { worker: workers[11], gross_salary: 6500.00, deductions: 650.00 },
  { worker: workers[12], gross_salary: 5000.00, deductions: 500.00 },
  { worker: workers[13], gross_salary: 4400.00, deductions: 440.00 },
  { worker: workers[14], gross_salary: 5700.00, deductions: 570.00 },
  { worker: workers[15], gross_salary: 4900.00, deductions: 490.00 },
  { worker: workers[16], gross_salary: 5400.00, deductions: 540.00 },
  { worker: workers[17], gross_salary: 4300.00, deductions: 430.00 },
  { worker: workers[18], gross_salary: 6000.00, deductions: 600.00 },
  { worker: workers[19], gross_salary: 4700.00, deductions: 470.00 }
]

pay_calc_details_data.each do |data|
  PayCalculationDetail.find_or_create_by!(pay_calculation: pay_calc, worker: data[:worker]) do |detail|
    detail.gross_salary = data[:gross_salary]
    detail.deductions = data[:deductions]
    detail.net_salary = data[:gross_salary] - data[:deductions]
  end
end

# Recalculate totals via model method
pay_calc.recalculate_overall_total!

puts "✓ Created pay calculation with #{PayCalculationDetail.count} details"

# Re-enable auditing
Audited.auditing_enabled = true

puts "\n🎉 Production seeding completed!"
puts "\n📊 Summary:"
puts "  Permissions: #{Permission.count}"
puts "  Roles: #{Role.count}"
puts "  Users: #{User.count}"
puts "  Units: #{Unit.count}"
puts "  Categories: #{Category.count}"
puts "  Blocks: #{Block.count}"
puts "  Vehicles: #{Vehicle.count}"
puts "  Workers: #{Worker.count}"
puts "  Inventories: #{Inventory.count}"
puts "  Work Order Rates: #{WorkOrderRate.count}"
puts "  Work Orders: #{WorkOrder.count}"
puts "  Work Order Workers: #{WorkOrderWorker.count}"
puts "  Work Order Items: #{WorkOrderItem.count}"
puts "  Pay Calculations: #{PayCalculation.count}"
puts "  Pay Calculation Details: #{PayCalculationDetail.count}"
puts "\n👤 Test Users:"
puts '  Superadmin: superadmin@example.com / ChangeMe123!'
puts '  Manager: manager@example.com / ChangeMe123!'
puts '  Field Conductor: conductor@example.com / ChangeMe123!'
puts '  Clerk: clerk@example.com / ChangeMe123!'
puts "\n⚠️  IMPORTANT: Change all user passwords immediately after first login!"
