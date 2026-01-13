# frozen_string_literal: true

require 'csv'

# Units Import Rake Tasks
namespace :units do
  desc 'Import units from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = UnitsImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV format'
  task :sample do
    UnitsSampleFormatter.display
  end

  desc 'List all units'
  task list: :environment do
    UnitsLister.display
  end

  desc 'Delete all units (dangerous!)'
  task delete_all: :environment do
    UnitsDeleter.execute
  end
end

# ================================
# UNITS IMPORTER
# ================================
class UnitsImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_units.csv').freeze

  def initialize(file_path = nil)
    @file_path = file_path || DEFAULT_CSV_PATH
    @stats = { total: 0, created: 0, updated: 0, skipped: 0, errors: 0 }
  end

  def import
    validate_file!
    header

    ActiveRecord::Base.transaction do
      parse_rows
      summary
    rescue StandardError => e
      abort_transaction(e)
    end
  end

  private

  attr_reader :file_path, :stats

  def validate_file!
    return if File.exist?(file_path)

    puts "File not found: #{file_path}"
    puts "Expected at: #{DEFAULT_CSV_PATH}"
    exit 1
  end

  def header
    puts "Importing units from #{file_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      UnitsRowProcessor.new(row, stats).process
    rescue StandardError => e
      puts "Unexpected error on row #{stats[:total]}: #{e.message}"
      stats[:errors] += 1
    end
  end

  def summary
    puts '=' * 80
    puts 'IMPORT SUMMARY'
    puts " Total rows: #{stats[:total]}"
    puts " Created:    #{stats[:created]}"
    puts " Updated:    #{stats[:updated]}"
    puts " Skipped:    #{stats[:skipped]}"
    puts " Errors:     #{stats[:errors]}"
    puts '=' * 80

    if stats[:errors].zero?
      puts '✓ Import completed successfully.'
    else
      puts '⚠ Import completed with errors.'
    end
  end

  def abort_transaction(error)
    puts "Transaction rolled back: #{error.message}"
    raise ActiveRecord::Rollback
  end
end

# ================================
# ROW PROCESSOR
# ================================
class UnitsRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @name      = row[:name]&.strip
    @unit_type = row[:unit_type]&.strip
  end

  def process
    return skip('name is missing') if name.blank?
    return skip('unit_type is missing') if unit_type.blank?

    upsert_unit
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :name, :unit_type

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  def upsert_unit
    unit = Unit.find_by(name: name)

    if unit
      unit.update!(unit_type: unit_type)
      puts "Updated: #{name} (#{unit_type})"
      stats[:updated] += 1
    else
      Unit.create!(name: name, unit_type: unit_type)
      puts "✓ Created: #{name} (#{unit_type})"
      stats[:created] += 1
    end
  end
end

# ================================
# SAMPLE FORMATTER
# ================================
class UnitsSampleFormatter
  def self.display
    puts 'Sample CSV format for units:'
    puts '=' * 80
    puts 'name,unit_type'
    puts 'Litres,Volume'
    puts 'Bag,Count'
    puts 'Gram,Weight'
    puts '=' * 80

    puts "\nCOLUMN DESCRIPTION:"
    puts ' name      - Unit name (required)'
    puts ' unit_type - Type/category of unit (required)'
  end
end

# ================================
# LIST UNITS
# ================================
class UnitsLister
  def self.display
    units = Unit.order(:name)

    if units.empty?
      puts 'No units found.'
      return
    end

    puts '=' * 80
    puts 'Units List'
    puts '=' * 80

    units.each do |u|
      puts "• #{u.name.ljust(20)} | #{u.unit_type}"
    end

    puts "\n#{units.count} total units"
  end
end

# ================================
# DELETE ALL UNITS
# ================================
class UnitsDeleter
  def self.execute
    count = Unit.count

    if count.zero?
      puts 'No units to delete.'
      return
    end

    puts "WARNING: This will delete all #{count} units!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == 'yes'
      Unit.delete_all
      puts "✓ Deleted all #{count} units"
    else
      puts 'Deletion cancelled.'
    end
  end
end
