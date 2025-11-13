# frozen_string_literal: true

namespace :db do
  desc 'Reset all sequences to match current max IDs'
  task reset_sequences: :environment do
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgres')
      ActiveRecord::Base.connection.tables.each do |table|
        # Skip schema migrations and internal tables
        next if %w[schema_migrations ar_internal_metadata].include?(table)

        begin
          ActiveRecord::Base.connection.execute(
            "SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) FROM #{table}), 1), true)"
          )
          puts "Reset sequence for #{table}"
        rescue StandardError => e
          # Skip tables without id column or sequence
          puts "Skipped #{table}: #{e.message}" if ENV['VERBOSE']
        end
      end

      puts 'All sequences have been reset!'
    else
      puts 'This task only works with PostgreSQL'
    end
  end

  desc 'Reset sequence for a specific table'
  task :reset_sequence, [:table_name] => :environment do |_t, args|
    table = args[:table_name]

    if table.blank?
      puts 'Usage: rake db:reset_sequence[table_name]'
      puts 'Example: rake db:reset_sequence[work_orders]'
      exit
    end

    if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgres')
      begin
        ActiveRecord::Base.connection.execute(
          "SELECT setval(pg_get_serial_sequence('#{table}', 'id'), COALESCE((SELECT MAX(id) FROM #{table}), 1), true)"
        )
        puts "Sequence reset successfully for #{table}!"
      rescue StandardError => e
        puts "Error: #{e.message}"
      end
    else
      puts 'This task only works with PostgreSQL'
    end
  end
end
