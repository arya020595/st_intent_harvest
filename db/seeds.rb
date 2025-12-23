# frozen_string_literal: true

# Main seeds file - Development environment only
#
# Usage:
#   rails db:seed   # Works only in development/test environments
#
# For production data seeding, use dedicated rake tasks instead.

# Block seeding in production environment
if Rails.env.production?
  puts '⚠️  SEEDING BLOCKED!'
  puts '─' * 80
  puts ''
  puts 'db:seed is disabled in production environment for security reasons.'
  puts 'Use dedicated rake tasks for production data management instead.'
  puts ''
  puts '─' * 80
  exit 1
end

puts 'Loading seeds...'
load(Rails.root.join('db', 'seeds', 'main.rb'))
