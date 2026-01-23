# frozen_string_literal: true

namespace :permissions do
  desc 'Seed permissions from db/seeds/data/permissions.rb'
  task seed: :environment do
    puts '=' * 80
    puts 'Starting Permission Seeding...'
    puts '=' * 80

    load Rails.root.join('db/seeds/data/permissions.rb')

    puts '=' * 80
    puts 'Permission seeding completed!'
    puts '=' * 80
  end

  desc 'Reset and re-seed all permissions (WARNING: Removes all existing permissions)'
  task reset: :environment do
    puts '=' * 80
    puts 'Resetting Permissions...'
    puts '=' * 80

    if Rails.env.production?
      print 'Are you sure you want to delete all permissions in PRODUCTION? (yes/no): '
      response = $stdin.gets.chomp
      unless response.downcase == 'yes'
        puts 'Operation cancelled.'
        exit
      end
    end

    Permission.destroy_all
    puts "✓ All permissions deleted (#{Permission.count} remaining)"

    puts "\nRe-seeding permissions..."
    load Rails.root.join('db/seeds/data/permissions.rb')

    puts '=' * 80
    puts 'Permission reset completed!'
    puts '=' * 80
  end

  desc 'Display all permissions grouped by section'
  task list: :environment do
    permissions = Permission.order(:section, :resource, :code)

    puts '=' * 80
    puts "Total Permissions: #{permissions.count}"
    puts '=' * 80

    current_section = nil
    permissions.each do |permission|
      if current_section != permission.section
        current_section = permission.section
        puts "\n#{current_section}:"
        puts '-' * 40
      end
      puts "  • #{permission.code.ljust(50)} (#{permission.name})"
    end

    puts '=' * 80
  end

  desc 'Verify permissions integrity (check for missing or orphaned permissions)'
  task verify: :environment do
    puts '=' * 80
    puts 'Verifying Permissions...'
    puts '=' * 80

    # Load expected permissions from file safely
    begin
      load Rails.root.join('db/seeds/data/permissions.rb')
    rescue LoadError => e
      puts "❌ Error loading permissions file: #{e.message}"
      exit 1
    end

    unless defined?(PERMISSION_RESOURCES)
      puts '❌ Error: PERMISSION_RESOURCES constant not found in permissions.rb'
      exit 1
    end

    expected_permissions = []
    PERMISSION_RESOURCES.each do |resource, actions|
      actions.each do |action|
        expected_permissions << "#{resource}.#{action}"
      end
    end

    # Check for missing permissions
    existing_codes = Permission.pluck(:code)
    missing = expected_permissions - existing_codes
    orphaned = existing_codes - expected_permissions

    if missing.any?
      puts "\n⚠️  Missing Permissions (#{missing.count}):"
      missing.each { |code| puts "  • #{code}" }
    else
      puts "\n✓ No missing permissions"
    end

    if orphaned.any?
      puts "\n⚠️  Orphaned Permissions (#{orphaned.count}):"
      orphaned.each { |code| puts "  • #{code}" }
    else
      puts "\n✓ No orphaned permissions"
    end

    puts "\n" + '=' * 80
    puts "Summary:"
    puts "  Expected: #{expected_permissions.count}"
    puts "  Existing: #{existing_codes.count}"
    puts "  Missing:  #{missing.count}"
    puts "  Orphaned: #{orphaned.count}"
    puts '=' * 80
  end
end
