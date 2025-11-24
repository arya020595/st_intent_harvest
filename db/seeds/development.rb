# frozen_string_literal: true

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
load Rails.root.join('db', 'seeds', 'permissions.rb')
puts "✓ Created #{Permission.count} permissions"

# Create Roles
puts 'Creating roles...'

# Superadmin - bypasses all permission checks
superadmin_role = Role.find_or_create_by!(name: 'Superadmin') do |role|
  role.description = 'Full system access (bypasses all permission checks)'
end
# Assign all permissions to superadmin
superadmin_role.permissions = Permission.all

# Manager - can view dashboard and approve work orders
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

# Field Conductor - can create and manage work order details (NO dashboard access)
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

# Clerk - administrative support with managed access to pay calculations, payslips, inventories, workers, and master data (NO dashboard access)
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

# Load Deduction Types
puts 'Loading deduction types...'
load Rails.root.join('db', 'seeds', 'deduction_types.rb')

# Create Blocks
puts 'Creating blocks...'
10.times do |i|
  block_number = "BLK-#{(i + 1).to_s.rjust(3, '0')}"

  Block.find_or_create_by!(block_number: block_number) do |block|
    block.hectarage = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('5.0'), BigDecimal('50.0'))
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
# For seeds, use the application's allowed nationality values
nationalities = %w[Local Foreigner]

50.times do |i|
  identity_number = "ID-#{(i + 1).to_s.rjust(3, '0')}"

  Worker.find_or_create_by!(identity_number: identity_number) do |worker|
    worker.name = Faker::Name.name
    worker.worker_type = worker_types.sample
    worker.gender = genders.sample
    worker.is_active = [true, true, true, false].sample # 75% active, 25% inactive
    worker.hired_date = Faker::Date.between(from: 10.years.ago, to: Date.today)
    # Use allowed nationality values directly
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
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('45.0'), BigDecimal('85.0'))
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
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('30.0'), BigDecimal('60.0'))
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
    inventory.price = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('15.0'), BigDecimal('50.0'))
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
    inventory.price = Faker::Number.decimal(l_digits: 4, r_digits: 2).clamp(BigDecimal('800.0'), BigDecimal('2500.0'))
    inventory.supplier = Faker::Company.name
    inventory.input_date = Faker::Date.between(from: 365.days.ago, to: Date.today)
  end
end

puts "✓ Created #{Inventory.count} inventory items"

# Create Work Order Rates
puts 'Creating work order rates...'
day_unit = Unit.find_by(name: 'Day')
hectare_unit = Unit.find_by(name: 'Hectare')
rate_types = %w[normal resources work_days]

# Day-based rates
day_based_work_orders = %w[Harvesting Spraying Fertilizing Weeding Pruning Planting]
day_based_work_orders.each do |work_order_name|
  WorkOrderRate.find_or_create_by!(work_order_name: work_order_name) do |rate|
    rate.rate = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('50.0'), BigDecimal('100.0'))
    sampled_rate_type = rate_types.sample
    rate.work_order_rate_type = sampled_rate_type
    rate.unit_id = day_unit.id.to_s unless sampled_rate_type == 'work_days'
  end
end

# Hectare-based rates
hectare_based_work_orders = ['Land Preparation', 'Land Clearing', 'Irrigation Setup']
hectare_based_work_orders.each do |work_order_name|
  WorkOrderRate.find_or_create_by!(work_order_name: work_order_name) do |rate|
    rate.rate = Faker::Number.decimal(l_digits: 3, r_digits: 2).clamp(BigDecimal('200.0'), BigDecimal('400.0'))
    sampled_rate_type = rate_types.sample
    rate.work_order_rate_type = sampled_rate_type
    rate.unit_id = hectare_unit.id.to_s unless sampled_rate_type == 'work_days'
  end
end

puts "✓ Created #{WorkOrderRate.count} work order rates"

# Create Work Orders
puts 'Creating work orders...'
blocks = Block.all.to_a
work_order_rates = WorkOrderRate.all.to_a
conductor_user = User.find_by(email: 'conductor@example.com')
work_order_statuses = %w[ongoing pending amendment_required completed]

# Generate work months for last 6 months
work_months = (0..5).map { |i| (Date.today - i.months).beginning_of_month }

20.times do |i|
  WorkOrder.find_or_create_by!(id: i + 1) do |wo|
    wo.block_id = blocks.sample.id
    wo.work_order_rate_id = work_order_rates.sample.id
    wo.start_date = Faker::Date.between(from: 60.days.ago, to: Date.today)
    wo.work_month = work_months.sample # Assign random month from last 6 months
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
      wow.rate = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('50.0'), BigDecimal('100.0'))

      # Calculate amount based on work_order_rate_type
      # Use Rails enum predicate method for clarity and convention
      if work_order.work_order_rate.work_days?
        # For work_days type: use work_days field
        wow.work_days = rand(1..26) # Random days worked in month (1-26)
        wow.amount = wow.rate * wow.work_days
      else
        # For normal/resources type: use work_area_size field
        wow.work_area_size = Faker::Number.decimal(l_digits: 2, r_digits: 2).clamp(BigDecimal('5.0'),
                                                                                   BigDecimal('50.0'))
        wow.amount = wow.rate * wow.work_area_size
      end

      wow.remarks = Faker::Lorem.sentence(word_count: 5)
    end
  end
end

puts "✓ Created #{WorkOrderWorker.count} work order workers relationships"

# Create Work Order Items
puts 'Creating work order items...'
inventories = Inventory.includes(:unit, :category).to_a

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
# Use model helper and current attribute names (total_gross_salary, total_deductions, total_net_salary)
pay_calc = PayCalculation.find_or_create_for_month('2024-10')

# Create Pay Calculation Details
puts 'Creating pay calculation details...'
Worker.where(is_active: true).limit(30).each do |worker|
  PayCalculationDetail.find_or_create_by!(pay_calculation: pay_calc, worker: worker) do |detail|
    gross = Faker::Number.decimal(l_digits: 4, r_digits: 2)
    gross = [[gross, BigDecimal('3000.00')].max, BigDecimal('10000.00')].min
    deduct = Faker::Number.decimal(l_digits: 3, r_digits: 2)
    deduct = [[deduct, BigDecimal('500.00')].max, BigDecimal('2500.00')].min
    detail.gross_salary = gross
    detail.deductions = deduct
    detail.net_salary = gross - deduct
  end
end

# Recalculate totals using model method
pay_calc.recalculate_overall_total!

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
