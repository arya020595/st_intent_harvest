namespace :db do
  desc "Reset all PostgreSQL sequences to match max IDs in tables"
  task reset_sequences: :environment do
    if Rails.env.production?
      puts "⚠️  WARNING: This will modify production database sequences!"
      puts "Proceeding to reset sequences..."
    end

    connection = ActiveRecord::Base.connection

    # Get all tables that have serial/bigserial primary keys
    tables = connection.tables.reject { |t| t.start_with?("pg_") || t == "schema_migrations" }

    reset_count = 0
    tables.each do |table|
      # Get the primary key column name
      pk_column = connection.primary_keys(table).first
      next unless pk_column

      # Check if it's a serial type
      column_info = connection.columns(table).find { |c| c.name == pk_column }
      next unless column_info&.type.to_s.match?(/serial|bigserial/)

      # Find the sequence name (usually table_id_seq)
      sequence_name = "#{table}_#{pk_column}_seq"

      # Get max ID from table
      max_id_result = connection.execute("SELECT MAX(#{pk_column}) FROM #{table}")
      max_id = max_id_result.first["max"] || 0

      # Reset sequence
      next_val = max_id.to_i + 1
      connection.execute("SELECT setval('#{sequence_name}', #{next_val})")

      puts "✓ #{table}: sequence set to #{next_val}"
      reset_count += 1
    end

    puts "\n✅ Reset #{reset_count} sequence(s)"
  rescue => e
    puts "❌ Error resetting sequences: #{e.message}"
    raise
  end
end
