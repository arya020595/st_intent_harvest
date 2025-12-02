# frozen_string_literal: true

require 'csv'

# Work Order Rates Import Rake Tasks
#
# This task follows SOLID principles:
# - Single Responsibility: Each method has one clear purpose
# - Open/Closed: Easy to extend with new import types
# - Dependency Inversion: Uses ActiveRecord abstractions
#
# Usage:
#   rake work_order_rates:import              # Import from default location
#   rake work_order_rates:import[custom.csv]  # Import from custom file
#   rake work_order_rates:list                # List all rates
#   rake work_order_rates:sample              # Show CSV format
namespace :work_order_rates do
  desc 'Import work order rates from CSV file'
  task :import, [:file_path] => :environment do |_t, args|
    importer = WorkOrderRatesImporter.new(args[:file_path])
    importer.import
  end

  desc 'Show sample CSV format for work order rates import'
  task :sample do
    WorkOrderRatesSampleFormatter.display
  end

  desc 'List all work order rates'
  task list: :environment do
    WorkOrderRatesLister.display
  end

  desc 'Delete all work order rates (use with caution!)'
  task delete_all: :environment do
    WorkOrderRatesDeleter.execute
  end
end

# Service class for importing work order rates
# Follows Single Responsibility Principle - only handles import logic
class WorkOrderRatesImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_work_order_rates.csv').freeze

  def initialize(file_path = nil)
    @file_path = file_path || DEFAULT_CSV_PATH
    @stats = initialize_stats
  end

  def import
    validate_file_exists!
    print_import_header

    ActiveRecord::Base.transaction do
      import_rows
      print_summary
    rescue StandardError => e
      handle_transaction_error(e)
    end
  end

  private

  attr_reader :file_path, :stats

  def initialize_stats
    {
      total: 0,
      created: 0,
      updated: 0,
      skipped: 0,
      errors: 0,
      units_created: 0
    }
  end

  def validate_file_exists!
    return if File.exist?(file_path)

    puts "Error: File not found at #{file_path}"
    puts 'Usage: rake work_order_rates:import[path/to/file.csv]'
    puts "Or place file at: #{DEFAULT_CSV_PATH}"
    exit 1
  end

  def print_import_header
    puts "Starting import from: #{file_path}"
    puts '=' * 80
  end

  def import_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      process_row(row)
    end
  end

  def process_row(row)
    row_processor = WorkOrderRateRowProcessor.new(row, stats)
    row_processor.process
  rescue StandardError => e
    handle_row_error(e, stats[:total])
  end

  def handle_row_error(error, row_number)
    puts "✗ Unexpected error on row #{row_number}: #{error.message}"
    stats[:errors] += 1
  end

  def print_summary
    puts '=' * 80
    puts 'Import Summary:'
    puts "  Total rows processed: #{stats[:total]}"
    puts "  Created: #{stats[:created]}"
    puts "  Updated: #{stats[:updated]}"
    puts "  Skipped: #{stats[:skipped]}"
    puts "  Errors: #{stats[:errors]}"
    puts "  New units created: #{stats[:units_created]}"
    puts '=' * 80

    if stats[:errors].positive?
      puts "\n⚠ Import completed with errors. Review the output above."
    else
      puts "\n✓ Import completed successfully!"
    end
  end

  def handle_transaction_error(error)
    puts "\n✗ Transaction rolled back due to error: #{error.message}"
    raise ActiveRecord::Rollback
  end
end

# Processes a single CSV row
# Follows Single Responsibility Principle - handles one row at a time
class WorkOrderRateRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats
    @work_order_name = extract_work_order_name
    @rate = extract_rate
    @unit_name = extract_unit_name
    @work_order_rate_type = extract_work_order_rate_type
  end

  def process
    return skip_blank_row if work_order_name.blank?
    return skip_invalid_type unless valid_work_order_rate_type?

    unit = find_or_create_unit
    upsert_work_order_rate(unit)
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_error(e)
  end

  private

  attr_reader :row, :stats, :work_order_name, :rate, :unit_name, :work_order_rate_type

  def extract_work_order_name
    row[:work_order_name]&.strip
  end

  def extract_rate
    row[:rate]&.to_f
  end

  def extract_unit_name
    row[:unit_of_measurement]&.strip
  end

  def extract_work_order_rate_type
    row[:work_order_rate_type]&.strip&.downcase || 'normal'
  end

  def skip_blank_row
    puts "⚠ Row #{stats[:total]}: Skipping - work_order_name is blank"
    stats[:skipped] += 1
  end

  def valid_work_order_rate_type?
    WorkOrderRate.work_order_rate_types.key?(work_order_rate_type)
  end

  def skip_invalid_type
    puts "⚠ Row #{stats[:total]}: Invalid work_order_rate_type '#{work_order_rate_type}' for '#{work_order_name}'"
    puts "  Valid types: #{WorkOrderRate.work_order_rate_types.keys.join(', ')}"
    stats[:errors] += 1
  end

  def find_or_create_unit
    return nil if unit_name.blank? || work_order_rate_type == 'work_days'

    unit = Unit.find_by(name: unit_name)
    return unit if unit

    create_unit
  end

  def create_unit
    unit = Unit.create!(name: unit_name)
    puts "  ✓ Created new unit: #{unit_name}"
    stats[:units_created] += 1
    unit
  end

  def upsert_work_order_rate(unit)
    work_order_rate = WorkOrderRate.find_by(work_order_name: work_order_name)

    if work_order_rate
      update_work_order_rate(work_order_rate, unit)
    else
      create_work_order_rate(unit)
    end
  end

  def update_work_order_rate(work_order_rate, unit)
    work_order_rate.update!(
      rate: rate,
      unit: unit,
      work_order_rate_type: work_order_rate_type
    )
    puts "✓ Updated: #{work_order_name} (#{rate} #{unit&.name || 'N/A'}) [#{work_order_rate_type}]"
    stats[:updated] += 1
  end

  def create_work_order_rate(unit)
    WorkOrderRate.create!(
      work_order_name: work_order_name,
      rate: rate,
      unit: unit,
      work_order_rate_type: work_order_rate_type
    )
    puts "✓ Created: #{work_order_name} (#{rate} #{unit&.name || 'N/A'}) [#{work_order_rate_type}]"
    stats[:created] += 1
  end

  def handle_validation_error(error)
    puts "✗ Error on row #{stats[:total]} (#{work_order_name}): #{error.message}"
    stats[:errors] += 1
  end
end

# Displays sample CSV format
# Follows Single Responsibility Principle - only handles display
class WorkOrderRatesSampleFormatter
  def self.display
    new.display
  end

  def display
    print_header
    print_sample_data
    print_column_descriptions
    print_notes
  end

  private

  def print_header
    puts 'Sample CSV format for work_order_rates import:'
    puts '=' * 80
  end

  def print_sample_data
    puts 'work_order_name,rate,unit_of_measurement,work_order_rate_type'
    sample_rows.each { |row| puts row }
    puts '=' * 80
  end

  def sample_rows
    [
      'Harvesting 4-Over 5 Years,42,Metric ton (M/ton),normal',
      'Harvesting Below 4 Years,47.25,Metric ton (M/ton),normal',
      'FFB Loading Above 6 years,5.5,Metric ton (M/ton),normal',
      'Manuring 0.5kg/palm,5.25,Bag,normal',
      'Circle and Path Spray,33.6,Ha,normal',
      'Loading and Unloading Seedling,0.4,Palm,normal',
      'Field Raking,0.2,Kg,normal',
      'EPB Mulching,4.2,Mt,normal'
    ]
  end

  def print_column_descriptions
    puts "\nColumn descriptions:"
    column_descriptions.each { |desc| puts "  #{desc}" }
  end

  def column_descriptions
    [
      'work_order_name        - Name of the work order (required)',
      'rate                   - Rate amount (numeric, optional)',
      'unit_of_measurement    - Unit name (will be created if not exists, optional for work_days type)',
      'work_order_rate_type   - Type: normal, resources, or work_days (default: normal)'
    ]
  end

  def print_notes
    puts "\nNotes:"
    notes.each { |note| puts "  - #{note}" }
  end

  def notes
    [
      'For work_order_rate_type "work_days", unit_of_measurement is ignored',
      'Units will be automatically created if they don\'t exist',
      'Existing work orders (matched by name) will be updated'
    ]
  end
end

# Lists all work order rates
# Follows Single Responsibility Principle - only handles listing
class WorkOrderRatesLister
  def self.display
    new.display
  end

  def display
    rates = fetch_rates
    return print_no_rates_message if rates.empty?

    print_header
    print_rates_by_type(rates)
    print_total(rates)
  end

  private

  def fetch_rates
    WorkOrderRate.includes(:unit).order(:work_order_name)
  end

  def print_no_rates_message
    puts 'No work order rates found in database'
  end

  def print_header
    puts '=' * 80
    puts 'Work Order Rates:'
    puts '=' * 80
  end

  def print_rates_by_type(rates)
    WorkOrderRate.work_order_rate_types.each_key do |type|
      print_type_section(type, rates)
    end
  end

  def print_type_section(type, rates)
    type_rates = rates.select { |r| r.work_order_rate_type == type }
    return if type_rates.empty?

    puts "\n#{type.upcase}:"
    type_rates.each { |rate| print_rate(rate) }
  end

  def print_rate(rate)
    unit_display = rate.unit&.name || 'N/A'
    puts "  • #{rate.work_order_name.ljust(40)} | #{rate.rate || 'N/A'} #{unit_display}"
  end

  def print_total(rates)
    puts "\n#{rates.count} total work order rates"
  end
end

# Deletes all work order rates with confirmation
# Follows Single Responsibility Principle - only handles deletion
class WorkOrderRatesDeleter
  def self.execute
    new.execute
  end

  def execute
    count = WorkOrderRate.count
    return print_no_rates_message if count.zero?

    if confirm_deletion?(count)
      delete_all_rates(count)
    else
      print_cancellation_message
    end
  end

  private

  def print_no_rates_message
    puts 'No work order rates to delete'
  end

  def confirm_deletion?(count)
    puts "WARNING: This will delete all #{count} work order rates!"
    print 'Are you sure? Type "yes" to confirm: '
    response = $stdin.gets.chomp
    response.downcase == 'yes'
  end

  def delete_all_rates(count)
    WorkOrderRate.delete_all
    puts "✓ Deleted all #{count} work order rates"
  end

  def print_cancellation_message
    puts 'Deletion cancelled'
  end
end
