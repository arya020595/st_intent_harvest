# Main seeds file - delegates to environment-specific seeds
#
# Usage:
#   rails db:seed                    # Auto-detect environment
#   SEED_ENV=production rails db:seed # Force production seeds
#   SEED_ENV=development rails db:seed # Force development seeds

if Rails.env.production? || ENV['SEED_ENV'] == 'production'
  puts 'Loading production seeds (minimal data)...'
  load(Rails.root.join('db', 'seeds', 'production.rb'))
else
  puts 'Loading development seeds (full fake data with Faker)...'
  load(Rails.root.join('db', 'seeds', 'development.rb'))
end
