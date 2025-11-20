# frozen_string_literal: true

# Production Seeds - Users
# Create default users with role assignments

puts '👤 Creating users...'

# Fetch roles once
roles = Role.pluck(:name, :id).to_h

# Define user configurations
user_configs = [
  {
    email: 'superadmin@example.com',
    name: 'Superadmin',
    password: 'ChangeMe123!',
    role_name: 'Superadmin'
  },
  {
    email: 'manager@example.com',
    name: 'Manager',
    password: 'ChangeMe123!',
    role_name: 'Manager'
  },
  {
    email: 'conductor@example.com',
    name: 'Field Conductor',
    password: 'ChangeMe123!',
    role_name: 'Field Conductor'
  },
  {
    email: 'clerk@example.com',
    name: 'Clerk',
    password: 'ChangeMe123!',
    role_name: 'Clerk'
  }
]

# Create users efficiently
user_configs.each do |config|
  User.find_or_create_by!(email: config[:email]) do |user|
    user.name = config[:name]
    user.password = config[:password]
    user.password_confirmation = config[:password]
    user.role_id = roles[config[:role_name]]
  end
end

puts "✓ Created #{User.count} users"
