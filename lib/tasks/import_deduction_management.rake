# frozen_string_literal: true

namespace :deductions do
  desc 'Import deduction types from CSV file (updates metadata if exists)'
  task :import_deduction_types, [:csv_file] => :environment do |_t, args|
    csv_file = args[:csv_file] || Rails.root.join('db/master_data/master_data_deductions/deduction_types.csv')

    unless File.exist?(csv_file)
      puts "Error: CSV file not found at #{csv_file}"
      exit 1
    end

    require 'csv'

    success_count = 0
    updated_count = 0
    error_count = 0
    skipped_count = 0

    puts "=== Importing Deduction Types from #{csv_file} ==="

    CSV.foreach(csv_file, headers: true) do |row|
      code = row['code']

      # Check if already exists
      existing = DeductionType.find_by(code: code, effective_until: nil)
      if existing
        # Update only metadata (name, description)
        # Skip if calculation_type would change (too risky)
        if existing.calculation_type != row['calculation_type']
          puts "⊘ Skipped #{code} - calculation_type change detected (use update task instead)"
          skipped_count += 1
          next
        end

        begin
          update_attrs = {
            name: row['name'],
            description: row['description'] || row['name']
          }

          # Handle effective_until if provided (for deprecating deductions)
          if row['effective_until'].present?
            update_attrs[:effective_until] = Date.parse(row['effective_until'])
            update_attrs[:is_active] = false
            puts "↻ Updated #{code} - #{existing.name} (deprecated: #{update_attrs[:effective_until]})"
          elsif row['is_active'].present?
            update_attrs[:is_active] = row['is_active'].downcase == 'true'
            puts "↻ Updated #{code} - #{existing.name} (active: #{update_attrs[:is_active]})"
          else
            puts "↻ Updated #{code} - #{existing.name}"
          end

          existing.update!(update_attrs)
          updated_count += 1
        rescue StandardError => e
          puts "✗ Failed to update #{code}: #{e.message}"
          error_count += 1
        end
        next
      end

      begin
        # Parse contributions (must be 0 for fixed type wage ranges, not nil)
        employee_contribution = row['employee_contribution'].present? ? row['employee_contribution'].to_f : 0
        employer_contribution = row['employer_contribution'].present? ? row['employer_contribution'].to_f : 0

        effective_from = row['effective_from'].present? ? Date.parse(row['effective_from']) : Date.current
        effective_until = row['effective_until'].present? ? Date.parse(row['effective_until']) : nil
        is_active = row['is_active'].present? ? (row['is_active'].downcase == 'true') : true

        deduction = DeductionType.create!(
          code: code,
          name: row['name'],
          description: row['description'] || row['name'],
          calculation_type: row['calculation_type'],
          employee_contribution: employee_contribution,
          employer_contribution: employer_contribution,
          applies_to_nationality: row['nationality'] || 'all',
          is_active: is_active,
          effective_from: effective_from,
          effective_until: effective_until
        )

        puts "✓ Created #{code} - #{deduction.name}"
        success_count += 1
      rescue StandardError => e
        puts "✗ Failed to create #{code}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n=== Import Summary ==="
    puts "✓ Created: #{success_count}"
    puts "↻ Updated: #{updated_count}"
    puts "⊘ Skipped: #{skipped_count}"
    puts "✗ Failed: #{error_count}"
  end

  desc 'Import wage ranges from CSV file (use force=true to replace all ranges for that deduction type)'
  task :import_wage_ranges, %i[csv_file force] => :environment do |_t, args|
    csv_file = args[:csv_file]
    force_mode = args[:force] == 'true'

    unless csv_file.present?
      puts 'Error: CSV file path is required'
      puts 'Usage: rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv]'
      puts '       rake deductions:import_wage_ranges[db/master_data/master_data_deductions/epf_local_wage_ranges.csv,true] # force replace'
      exit 1
    end

    unless File.exist?(csv_file)
      puts "Error: CSV file not found at #{csv_file}"
      exit 1
    end

    require 'csv'

    success_count = 0
    error_count = 0
    skipped_count = 0
    deleted_count = 0

    puts "=== Importing Wage Ranges from #{csv_file} ==="
    puts "Mode: #{force_mode ? 'FORCE REPLACE' : 'Skip existing'}\n\n"

    # If force mode, collect all deduction types first and delete their ranges
    if force_mode
      deduction_codes = []
      CSV.foreach(csv_file, headers: true) do |row|
        deduction_codes << row['code']
      end
      deduction_codes.uniq!

      deduction_codes.each do |code|
        deduction_type = DeductionType.find_by(code: code, effective_until: nil)
        next unless deduction_type

        count = DeductionWageRange.where(deduction_type: deduction_type).count
        DeductionWageRange.where(deduction_type: deduction_type).destroy_all
        deleted_count += count
        puts "🗑  Deleted #{count} existing ranges for #{code}"
      end
      puts ''
    end

    CSV.foreach(csv_file, headers: true) do |row|
      code = row['code']
      min_wage = row['min_wage'].to_f
      max_wage = row['max_wage'].present? ? row['max_wage'].to_f : nil

      # Find deduction type
      deduction_type = DeductionType.find_by(code: code, effective_until: nil)
      unless deduction_type
        puts "✗ Deduction type #{code} not found - skipping range #{min_wage}-#{max_wage || 'unlimited'}"
        skipped_count += 1
        next
      end

      # Check if range already exists (only in non-force mode)
      unless force_mode
        existing = DeductionWageRange.find_by(
          deduction_type: deduction_type,
          min_wage: min_wage,
          max_wage: max_wage
        )

        if existing
          skipped_count += 1
          next
        end
      end

      begin
        DeductionWageRange.create!(
          deduction_type: deduction_type,
          min_wage: min_wage,
          max_wage: max_wage,
          employee_amount: row['employee_amount'].to_f,
          employer_amount: row['employer_amount'].to_f,
          calculation_method: row['calculation_method'] || 'fixed'
        )

        success_count += 1
        print '.' if success_count % 10 == 0
      rescue StandardError => e
        puts "\n✗ Failed to create range #{code} #{min_wage}-#{max_wage || 'unlimited'}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n\n=== Import Summary ==="
    puts "🗑  Deleted: #{deleted_count}" if force_mode
    puts "✓ Created: #{success_count}"
    puts "⊘ Skipped: #{skipped_count}"
    puts "✗ Failed: #{error_count}"
  end

  desc 'Import all wage ranges from db/master_data/master_data_deductions directory (use replace=true to wipe and reimport all)'
  task :import_all_wage_ranges, [:replace] => :environment do |_t, args|
    replace_mode = args[:replace] == 'true'

    csv_files = [
      'epf_local_wage_ranges.csv',
      'socso_wage_ranges.csv',
      'eis_local_wage_ranges.csv'
    ]

    puts '=== Importing All Wage Ranges ==='
    puts "Mode: #{replace_mode ? 'REPLACE ALL' : 'Skip existing'}\n\n"

    total_success = 0
    total_errors = 0
    total_skipped = 0
    total_deleted = 0

    # If replace mode, delete all wage ranges first
    if replace_mode
      puts '🗑  Deleting all existing wage ranges...'
      count = DeductionWageRange.count
      DeductionWageRange.destroy_all
      total_deleted = count
      puts "🗑  Deleted #{count} wage ranges\n\n"
    end

    csv_files.each do |filename|
      csv_path = Rails.root.join('db/master_data/master_data_deductions', filename)

      unless File.exist?(csv_path)
        puts "⊘ Skipped #{filename} - file not found"
        next
      end

      puts "\n--- Processing #{filename} ---"

      require 'csv'
      success = 0
      errors = 0
      skipped = 0

      CSV.foreach(csv_path, headers: true) do |row|
        code = row['code']
        min_wage = row['min_wage'].to_f
        max_wage = row['max_wage'].present? ? row['max_wage'].to_f : nil

        deduction_type = DeductionType.find_by(code: code, effective_until: nil)
        unless deduction_type
          skipped += 1
          next
        end

        # Check if range already exists (only in non-replace mode)
        unless replace_mode
          existing = DeductionWageRange.find_by(
            deduction_type: deduction_type,
            min_wage: min_wage,
            max_wage: max_wage
          )

          if existing
            skipped += 1
            next
          end
        end

        begin
          DeductionWageRange.create!(
            deduction_type: deduction_type,
            min_wage: min_wage,
            max_wage: max_wage,
            employee_amount: row['employee_amount'].to_f,
            employer_amount: row['employer_amount'].to_f,
            calculation_method: row['calculation_method'] || 'fixed'
          )
          success += 1
          print '.' if success % 10 == 0
        rescue StandardError
          errors += 1
        end
      end

      puts "\n  ✓ Created: #{success} | ⊘ Skipped: #{skipped} | ✗ Failed: #{errors}"

      total_success += success
      total_errors += errors
      total_skipped += skipped
    end

    puts "\n=== Overall Summary ==="
    puts "🗑  Total Deleted: #{total_deleted}" if replace_mode
    puts "✓ Total Created: #{total_success}"
    puts "⊘ Total Skipped: #{total_skipped}"
    puts "✗ Total Failed: #{total_errors}"
  end
end
