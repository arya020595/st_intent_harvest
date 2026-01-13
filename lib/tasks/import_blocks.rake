# frozen_string_literal: true

require 'csv'

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

# ================================
# Blocks Importer
# ================================
class BlocksImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_blocks.csv').freeze

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
    { total: 0, created: 0, updated: 0, skipped: 0, errors: 0 }
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
    BlockRowProcessor.new(row, stats).process
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
    puts stats[:errors].positive? ? "\n⚠ Import completed with errors." : "\n✓ Import completed successfully!"
  end

  def handle_transaction_error(error)
    puts "\n✗ Transaction rolled back due to error: #{error.message}"
    raise ActiveRecord::Rollback
  end
end

# ================================
# Block Row Processor
# ================================
class BlockRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats
    @block_number = extract_block_number
    @hectarage = extract_hectarage
  end

  def process
    return skip_blank_block if block_number.blank?

    upsert_block
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_error(e)
  end

  private

  attr_reader :row, :stats, :block_number
  attr_accessor :hectarage

  def extract_block_number
    row[:block_number]&.strip
  end

  def extract_hectarage
    Float(row[:hectarage]&.strip)
  rescue StandardError
    nil
  end

  def skip_blank_block
    puts "⚠ Row #{stats[:total]}: Skipping - block_number is blank"
    stats[:skipped] += 1
  end

  def upsert_block
    block = Block.find_by(block_number: block_number)
    if block
      block.update!(hectarage: hectarage)
      puts "✓ Updated: #{block_number} (#{hectarage} Ha)"
      stats[:updated] += 1
    else
      Block.create!(block_number: block_number, hectarage: hectarage)
      puts "✓ Created: #{block_number} (#{hectarage} Ha)"
      stats[:created] += 1
    end
  end

  def handle_validation_error(error)
    puts "✗ Error on row #{stats[:total]} (#{block_number}): #{error.message}"
    stats[:errors] += 1
  end
end

# ================================
# Blocks Sample Formatter
# ================================
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
    ['A1,24.79', 'A2,20.57', 'A3,21.43', 'B1,19.72', 'B2,25.72', 'C1,14.08', 'Workshop,0', 'Security,0'].each do |row|
      puts row
    end
    puts '=' * 80
  end

  def print_column_descriptions
    puts "\nColumn descriptions:"
    ['block_number - Unique block identifier (required)',
     'hectarage    - Size of block in hectares (numeric, 0 allowed)'].each { |desc| puts "  #{desc}" }
  end

  def print_notes
    puts "\nNotes:"
    [
      'Block numbers are case-sensitive (A1 ≠ a1)',
      'Hectarage must be a number >= 0 (0 is valid, negative values are invalid)',
      'Existing blocks (matched by block_number) will be updated'
    ].each { |note| puts "  - #{note}" }
  end
end

# ================================
# Blocks Lister
# ================================
class BlocksLister
  def self.display
    new.display
  end

  def display
    blocks = Block.order(:block_number)
    if blocks.empty?
      puts 'No blocks found in database'
      return
    end

    puts '=' * 80
    puts 'Blocks:'
    puts '=' * 80
    blocks.each { |b| puts "  • #{b.block_number.ljust(20)} | #{b.hectarage} Ha" }
    total_hectarage = blocks.sum(&:hectarage)
    puts "\n#{blocks.count} total blocks | Total hectarage: #{total_hectarage.round(2)} Ha"
  end
end

# ================================
# Blocks Deleter
# ================================
class BlocksDeleter
  def self.execute
    new.execute
  end

  def execute
    count = Block.count
    if count.zero?
      puts 'No blocks to delete'
      return
    end

    puts "WARNING: This will delete all #{count} blocks!"
    print 'Are you sure? Type "yes" to confirm: '
    response = $stdin.gets.chomp
    if response.downcase == 'yes'
      Block.delete_all
      puts "✓ Deleted all #{count} blocks"
    else
      puts 'Deletion cancelled'
    end
  end
end
