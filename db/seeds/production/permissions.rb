# frozen_string_literal: true

# Production Seeds - Permissions
# Load all permissions from the permissions configuration file

puts '📋 Creating permissions...'

# Load permissions from the shared configuration
permissions_file = Rails.root.join('db', 'seeds', 'permissions.rb')
load permissions_file

puts "✓ Created #{Permission.count} permissions"
