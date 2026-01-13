# frozen_string_literal: true

require 'csv'

# Categories Import Rake Tasks
namespace :categories do
  desc 'Import categories from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = CategoriesImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV format'
  task :sample do
    CategoriesSampleFormatter.display
  end

  desc 'List all categories'
  task list: :environment do
    CategoriesLister.display
  end

  desc 'Delete all categories (dangerous!)'
  task delete_all: :environment do
    CategoriesDeleter.execute
  end
end

# ================================
# CATEGORIES IMPORTER
# ================================
class CategoriesImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_category.csv').freeze

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
    puts "Importing categories from #{file_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      CategoriesRowProcessor.new(row, stats).process
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
class CategoriesRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @name        = row[:category_type]&.strip
    @parent_name = row[:parent_category]&.strip
  end

  def process
    return skip('name is missing') if name.blank?

    upsert_category
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :name, :parent_name

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  def upsert_category
    # Find parent by name unless parent is "-"
    parent = parent_name.present? && parent_name != '-' ? Category.find_by(name: parent_name) : nil

    category = Category.find_by(name: name)

    if category
      category.update!(parent_id: parent&.id)
      puts "Updated: #{name} (Parent: #{parent_name || '-'})"
      stats[:updated] += 1
    else
      Category.create!(name: name, parent_id: parent&.id)
      puts "✓ Created: #{name} (Parent: #{parent_name || '-'})"
      stats[:created] += 1
    end
  end
end

# ================================
# SAMPLE FORMATTER
# ================================
class CategoriesSampleFormatter
  def self.display
    puts 'Sample CSV format for categories:'
    puts '=' * 80
    puts 'category_type,parent_category'
    puts 'Diesel,-'
    puts 'Petrol,-'
    puts 'Spare Part,-'
    puts '=' * 80

    puts "\nCOLUMN DESCRIPTION:"
    puts ' category_type   - Name of the category (required)'
    puts " parent_category - Parent category name or '-' if none (required)"
  end
end

# ================================
# LIST CATEGORIES
# ================================
class CategoriesLister
  def self.display
    categories = Category.order(:name)

    if categories.empty?
      puts 'No categories found.'
      return
    end

    puts '=' * 80
    puts 'Categories List'
    puts '=' * 80

    categories.each do |c|
      parent_name = c.parent&.name || '-'
      puts "• #{c.name.ljust(30)} | Parent: #{parent_name}"
    end

    puts "\n#{categories.count} total categories"
  end
end

# ================================
# DELETE ALL CATEGORIES
# ================================
class CategoriesDeleter
  def self.execute
    count = Category.count

    if count.zero?
      puts 'No categories to delete.'
      return
    end

    puts "WARNING: This will delete all #{count} categories!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == 'yes'
      Category.delete_all
      puts "✓ Deleted all #{count} categories"
    else
      puts 'Deletion cancelled.'
    end
  end
end
