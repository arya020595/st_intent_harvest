# frozen_string_literal: true

# This file should run LAST (hence the 999 prefix)
# It resets all PostgreSQL sequences to prevent duplicate key errors
# This is especially important after seeding data with specific IDs

if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgres')
  puts "\n🔄 Resetting all database sequences..."

  reset_count = 0
  ActiveRecord::Base.connection.tables.each do |table|
    next if %w[schema_migrations ar_internal_metadata].include?(table)

    begin
      ActiveRecord::Base.connection.execute(
        "SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) FROM #{table}), 1), true)"
      )
      reset_count += 1
    rescue StandardError => e
      # Skip tables without id column or sequence
      Rails.logger.debug("Skipped #{table}: #{e.message}")
    end
  end

  puts "✅ Reset #{reset_count} sequences successfully!"
else
  puts '⚠️  Sequence reset only works with PostgreSQL'
end
