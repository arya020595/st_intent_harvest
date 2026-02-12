# frozen_string_literal: true

# Main Seeds Orchestrator
# Usage: rails db:seed (development/test only)
#
# This file orchestrates the seeding process by loading modular seed files
# in the correct dependency order. Each module is responsible for its own
# domain context following SOLID principles.

puts '🌱 Starting seed process...'
puts "📅 Seeding at: #{Time.current}"
puts '─' * 80

# Disable auditing during seeds for performance
Audited.auditing_enabled = false

# ============================================================================
# CLEANUP PHASE
# ============================================================================
puts "\n🧹 Cleanup Phase: Removing existing data..."
puts '─' * 80

# Clean up existing data (in reverse order of dependencies)
# Using delete_all with disable_referential_integrity for clean slate
ActiveRecord::Base.connection.disable_referential_integrity do
  cleanup_models = [
    PayCalculationDetail,
    PayCalculation,
    WorkOrderItem,
    WorkOrderWorker,
    WorkOrder,
    InventoryOrder,
    Inventory,
    Production,
    WorkOrderRate,
    User,
    RolesPermission,
    Role,
    Permission,
    Worker,
    Block,
    Vehicle,
    Unit,
    Category,
    DeductionType,
    Manday
  ]

  cleanup_models.each do |model|
    count = model.count
    model.delete_all
    puts "  ✓ Deleted #{count} #{model.name.pluralize}"
  end
end

puts "\n✅ Cleanup completed"

# ============================================================================
# SEEDING PHASE
# ============================================================================
puts "\n🌱 Seeding Phase: Creating data..."
puts '─' * 80

# Define seed modules in dependency order
seed_modules = [
  'permissions',        # Foundation: Permission definitions
  'roles',              # Roles with permission assignments
  'users',              # Users with role assignments
  'deduction_types',    # Deduction type definitions (EPF, SOCSO, EIS)
  'master_data',        # Units, Categories, Blocks, Vehicles
  'workers',            # Worker records
  'inventories',        # Inventory items
  'work_order_rates',   # Work order rate definitions
  'work_orders',        # Work orders with workers and items
  'pay_calculations',   # Pay calculations and details
  'productions',        # Daily production records
  'reset_sequences'     # Reset PostgreSQL sequences (must be last)
]

# Load each seed module
seed_modules.each_with_index do |module_name, index|
  puts "\n[#{index + 1}/#{seed_modules.size}] Loading #{module_name}..."
  puts '─' * 80

  seed_file = Rails.root.join('db', 'seeds', 'data', "#{module_name}.rb")

  begin
    load seed_file
  rescue StandardError => e
    puts "❌ Error loading #{module_name}: #{e.message}"
    puts e.backtrace.first(5)
    raise e
  end
end

# ============================================================================
# FINALIZATION PHASE
# ============================================================================
puts "\n🎉 Seeding completed successfully!"
puts '─' * 80

# Re-enable auditing
Audited.auditing_enabled = true

# Display summary
puts "\n📊 Seeding Summary:"
puts '─' * 80
summary_models = [
  { name: 'Permissions', model: Permission },
  { name: 'Roles', model: Role },
  { name: 'Users', model: User },
  { name: 'Units', model: Unit },
  { name: 'Categories', model: Category },
  { name: 'Blocks', model: Block },
  { name: 'Vehicles', model: Vehicle },
  { name: 'Workers', model: Worker },
  { name: 'Inventories', model: Inventory },
  { name: 'Work Order Rates', model: WorkOrderRate },
  { name: 'Work Orders', model: WorkOrder },
  { name: 'Work Order Workers', model: WorkOrderWorker },
  { name: 'Work Order Items', model: WorkOrderItem },
  { name: 'Pay Calculations', model: PayCalculation },
  { name: 'Pay Calculation Details', model: PayCalculationDetail },
  { name: 'Productions', model: Production }
]

summary_models.each do |item|
  count = item[:model].count
  puts "  #{item[:name].ljust(25)}: #{count.to_s.rjust(5)} records"
end

puts "\n✨ Seeding completed at: #{Time.current}"
puts '─' * 80
