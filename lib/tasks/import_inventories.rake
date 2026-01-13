# frozen_string_literal: true

require 'csv'

namespace :inventories do
  desc 'Import inventories from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = InventoriesImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV structure'
  task :sample do
    InventoriesSampleFormatter.display
  end

  desc 'List all inventories'
  task list: :environment do
    InventoriesLister.display
  end

  desc 'Delete all inventories'
  task delete_all: :environment do
    InventoriesDeleter.execute
  end
end

# =====================================================
# INVENTORIES IMPORTER
# =====================================================
class InventoriesImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_inventories.csv').freeze

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
    puts "Importing inventories from #{file_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      InventoriesRowProcessor.new(row, stats).process
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
  end

  def abort_transaction(error)
    puts "Transaction rolled back: #{error.message}"
    raise ActiveRecord::Rollback
  end
end

# =====================================================
# INVENTORY ROW PROCESSOR
# =====================================================
class InventoriesRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @name     = row[:name]&.strip
    @category = row[:category]&.strip
    @unit     = row[:unit]&.strip
  end

  def process
    return skip('name is missing') if @name.blank?
    return skip('category is missing') if @category.blank?
    return skip('unit is missing') if @unit.blank?

    category_id = lookup_category
    unit_id = lookup_unit

    return skip("category '#{@category}' not found") if category_id.nil?
    return skip("unit '#{@unit}' not found") if unit_id.nil?

    upsert_inventory(category_id, unit_id)
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :stats

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  # Category lookup by name
  def lookup_category
    Category.find_by(name: @category)&.id
  end

  # Unit lookup by name
  def lookup_unit
    Unit.find_by(name: @unit)&.id
  end

  # Upsert using name as unique key
  def upsert_inventory(category_id, unit_id)
    inventory = Inventory.find_by(name: @name)

    if inventory
      inventory.update!(
        category_id: category_id,
        unit_id: unit_id
      )
      puts "Updated: #{@name}"
      stats[:updated] += 1
    else
      Inventory.create!(
        name: @name,
        category_id: category_id,
        unit_id: unit_id
      )
      puts "✓ Created: #{@name}"
      stats[:created] += 1
    end
  end
end

# =====================================================
# SAMPLE FORMATTER
# =====================================================
class InventoriesSampleFormatter
  def self.display
    puts 'Sample CSV format for inventories:'
    puts '=' * 80
    puts 'name,category,unit'
    puts 'Pencil,Stationery,Piece'
    puts 'Cement,Building Materials,Bag'
    puts '=' * 80
  end
end

# =====================================================
# LIST INVENTORIES
# =====================================================
class InventoriesLister
  def self.display
    inventories = Inventory.includes(:category, :unit).order(:name)

    if inventories.empty?
      puts 'No inventories found.'
      return
    end

    puts '=' * 80
    puts 'Inventories List'
    puts '=' * 80

    inventories.each do |i|
      puts "• #{i.name.ljust(30)} | Category: #{i.category&.name.to_s.ljust(20)} | Unit: #{i.unit&.name}"
    end

    puts "\n#{inventories.count} total inventories"
  end
end

# =====================================================
# DELETE ALL INVENTORIES
# =====================================================
class InventoriesDeleter
  def self.execute
    count = Inventory.count
    if count.zero?
      puts 'No inventories to delete.'
      return
    end

    puts "WARNING: This will delete all #{count} inventories!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == 'yes'
      Inventory.delete_all
      puts "✓ Deleted all #{count} inventories"
    else
      puts 'Deletion cancelled.'
    end
  end
end
