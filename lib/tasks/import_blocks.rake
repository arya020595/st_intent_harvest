# frozen_string_literal: true

require 'csv'

# Blocks Import Rake Tasks
#
# This task follows SOLID principles:
# - Single Responsibility: Each method has one clear purpose
# - Open/Closed: Easy to extend with new import types
# - Dependency Inversion: Uses ActiveRecord abstractions
#
# Usage:
#   rake blocks:import              # Import from default location
#   rake blocks:import[custom.csv]  # Import from custom file
#   rake blocks:list                # List all blocks
#   rake blocks:sample              # Show CSV format
namespace :blocks do
  desc 'Import blocks from CSV file'
  task :import, [:file_path] => :environment do |_t, args|
    importer = BlocksImporter.new(args[:file_path])
    importer.import
  end

  desc 'Show sample CSV format for blocks import'
  task :sample do
    BlocksSampleFormatter.display
  end

  desc 'List all blocks'
  task list: :environment do
    BlocksLister.display
  end

  desc 'Delete all blocks (use with caution!)'
  task delete_all: :environment do
    BlocksDeleter.execute
  end
end

# Service class for importing blocks
# Follows Single Responsibility Principle - only handles import logic
class BlocksImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_bloks .csv').freeze

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
      errors: 0
    }
  end

  def validate_file_exists!
    return if File.exist?(file_path)

    puts "Error: File not found at #{file_path}"
    puts 'Usage: rake blocks:import[path/to/file.csv]'
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
    row_processor = BlockRowProcessor.new(row, stats)
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
class BlockRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats
    @block_number = extract_block_number
    @hectarage = extract_hectarage
  end

  def process
    return skip_blank_row if block_number.blank?

    upsert_block
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_error(e)
  end

  private

  attr_reader :row, :stats, :block_number, :hectarage

  def extract_block_number
    row[:block_number]&.strip
  end

  def extract_hectarage
    row[:hectarage]&.to_f
  end

  def skip_blank_row
    puts "⚠ Row #{stats[:total]}: Skipping - block_number is blank"
    stats[:skipped] += 1
  end

  def upsert_block
    block = Block.find_by(block_number: block_number)

    if block
      update_block(block)
    else
      create_block
    end
  end

  def update_block(block)
    block.update!(hectarage: hectarage)
    puts "✓ Updated: #{block_number} (#{hectarage} Ha)"
    stats[:updated] += 1
  end

  def create_block
    Block.create!(
      block_number: block_number,
      hectarage: hectarage
    )
    puts "✓ Created: #{block_number} (#{hectarage} Ha)"
    stats[:created] += 1
  end

  def handle_validation_error(error)
    puts "✗ Error on row #{stats[:total]} (#{block_number}): #{error.message}"
    stats[:errors] += 1
  end
end

# Displays sample CSV format
# Follows Single Responsibility Principle - only handles display
class BlocksSampleFormatter
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
    puts 'Sample CSV format for blocks import:'
    puts '=' * 80
  end

  def print_sample_data
    puts 'block_number,hectarage'
    sample_rows.each { |row| puts row }
    puts '=' * 80
  end

  def sample_rows
    [
      'A1,24.79',
      'A2,20.57',
      'A3,21.43',
      'B1,19.72',
      'B2,25.72',
      'C1,14.08',
      'C2,14.72'
    ]
  end

  def print_column_descriptions
    puts "\nColumn descriptions:"
    column_descriptions.each { |desc| puts "  #{desc}" }
  end

  def column_descriptions
    [
      'block_number - Unique block identifier (required, e.g., A1, B2, C3)',
      'hectarage    - Size of the block in hectares (numeric, required)'
    ]
  end

  def print_notes
    puts "\nNotes:"
    notes.each { |note| puts "  - #{note}" }
  end

  def notes
    [
      'Block numbers are case-sensitive (A1 ≠ a1)',
      'Hectarage must be a positive number',
      'Existing blocks (matched by block_number) will be updated'
    ]
  end
end

# Lists all blocks
# Follows Single Responsibility Principle - only handles listing
class BlocksLister
  def self.display
    new.display
  end

  def display
    blocks = fetch_blocks
    return print_no_blocks_message if blocks.empty?

    print_header
    print_blocks(blocks)
    print_total(blocks)
  end

  private

  def fetch_blocks
    Block.order(:block_number)
  end

  def print_no_blocks_message
    puts 'No blocks found in database'
  end

  def print_header
    puts '=' * 80
    puts 'Blocks:'
    puts '=' * 80
  end

  def print_blocks(blocks)
    blocks.each { |block| print_block(block) }
  end

  def print_block(block)
    puts "  • #{block.block_number.ljust(15)} | #{block.hectarage} Ha"
  end

  def print_total(blocks)
    total_hectarage = blocks.sum(&:hectarage)
    puts "\n#{blocks.count} total blocks | Total hectarage: #{total_hectarage.round(2)} Ha"
  end
end

# Deletes all blocks with confirmation
# Follows Single Responsibility Principle - only handles deletion
class BlocksDeleter
  def self.execute
    new.execute
  end

  def execute
    count = Block.count
    return print_no_blocks_message if count.zero?

    if confirm_deletion?(count)
      delete_all_blocks(count)
    else
      print_cancellation_message
    end
  end

  private

  def print_no_blocks_message
    puts 'No blocks to delete'
  end

  def confirm_deletion?(count)
    puts "WARNING: This will delete all #{count} blocks!"
    print 'Are you sure? Type "yes" to confirm: '
    response = $stdin.gets.chomp
    response.downcase == 'yes'
  end

  def delete_all_blocks(count)
    Block.delete_all
    puts "✓ Deleted all #{count} blocks"
  end

  def print_cancellation_message
    puts 'Deletion cancelled'
  end
end
