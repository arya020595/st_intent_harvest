# frozen_string_literal: true

# Production Seeds - Main Entry Point
# Usage: SEED_ENV=production rails db:seed
#
# This file orchestrates the seeding process by loading modular seed files
# in the correct dependency order. Each module is responsible for its own
# domain context following SOLID principles.

puts '🌱 Starting production seed process...'
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
# Production only cleans authentication/authorization tables
cleanup_models = [
  User,
  RolesPermission,
  Role,
  Permission
]

cleanup_models.each do |model|
  count = model.count
  model.destroy_all
  puts "  ✓ Deleted #{count} #{model.name.pluralize}"
end

puts "\n✅ Cleanup completed"

# ============================================================================
# SEEDING PHASE
# ============================================================================
puts "\n🌱 Seeding Phase: Creating production data..."
puts '─' * 80

# Define seed modules in dependency order
# Production only seeds essential authentication/authorization data
seed_modules = [
  'permissions',      # Foundation: Permission definitions
  'roles',            # Roles with permission assignments
  'users'             # Users with role assignments
]

# Load each seed module
seed_modules.each_with_index do |module_name, index|
  puts "\n[#{index + 1}/#{seed_modules.size}] Loading #{module_name}..."
  puts '─' * 80

  seed_file = Rails.root.join('db', 'seeds', 'production', "#{module_name}.rb")

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
puts "\n🎉 Production seeding completed successfully!"
puts '─' * 80

# Re-enable auditing
Audited.auditing_enabled = true

# Display summary
puts "\n📊 Seeding Summary:"
puts '─' * 80
summary_models = [
  { name: 'Permissions', model: Permission },
  { name: 'Roles', model: Role },
  { name: 'Users', model: User }
]

summary_models.each do |item|
  count = item[:model].count
  puts "  #{item[:name].ljust(25)}: #{count.to_s.rjust(5)} records"
end

puts "\n👤 Test User Credentials:"
puts '─' * 80
puts '  Email                      | Password      | Role'
puts '  ---------------------------|---------------|----------------'
puts '  superadmin@example.com     | ChangeMe123!  | Superadmin'
puts '  manager@example.com        | ChangeMe123!  | Manager'
puts '  conductor@example.com      | ChangeMe123!  | Field Conductor'
puts '  clerk@example.com          | ChangeMe123!  | Clerk'

puts "\n⚠️  IMPORTANT SECURITY NOTICE:"
puts '─' * 80
puts '  🔐 Change all user passwords immediately after first login!'
puts '  🔐 These default credentials should NEVER be used in production!'
puts '  🔐 Consider implementing password rotation policies.'

puts "\n✨ Seeding completed at: #{Time.current}"
puts '─' * 80
