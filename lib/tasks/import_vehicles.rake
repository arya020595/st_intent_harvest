# frozen_string_literal: true

require 'csv'

# Vehicles Import Rake Tasks
namespace :vehicles do
  desc 'Import vehicles from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = VehiclesImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV format'
  task :sample do
    VehiclesSampleFormatter.display
  end

  desc 'List all vehicles'
  task list: :environment do
    VehiclesLister.display
  end

  desc 'Delete all vehicles (dangerous!)'
  task delete_all: :environment do
    VehiclesDeleter.execute
  end
end

# ================================
# VEHICLES IMPORTER
# ================================
class VehiclesImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_vehicle.csv').freeze

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
    puts "Importing vehicles from #{file_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      VehiclesRowProcessor.new(row, stats).process
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
class VehiclesRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @vehicle_number = row[:vehicle_number]&.strip
    @vehicle_model  = row[:vehicle_model]&.strip
  end

  def process
    return skip('vehicle_number is missing') if vehicle_number.blank?
    return skip('vehicle_model is missing') if vehicle_model.blank?

    upsert_vehicle
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :vehicle_number, :vehicle_model

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  def upsert_vehicle
    vehicle = Vehicle.find_by(vehicle_number: vehicle_number)

    if vehicle
      vehicle.update!(vehicle_model: vehicle_model)
      puts "Updated: #{vehicle_number} (#{vehicle_model})"
      stats[:updated] += 1
    else
      Vehicle.create!(vehicle_number: vehicle_number, vehicle_model: vehicle_model)
      puts "✓ Created: #{vehicle_number} (#{vehicle_model})"
      stats[:created] += 1
    end
  end
end

# ================================
# SAMPLE FORMATTER
# ================================
class VehiclesSampleFormatter
  def self.display
    puts 'Sample CSV format for vehicles:'
    puts '=' * 80
    puts 'vehicle_number,vehicle_model'
    puts 'V001,Toyota Hiace'
    puts 'V002,Hino 500'
    puts 'V003,Mitsubishi Canter'
    puts '=' * 80

    puts "\nCOLUMN DESCRIPTION:"
    puts ' vehicle_number - Unique identifier for vehicle (required)'
    puts ' vehicle_model  - Model of the vehicle (required)'
  end
end

# ================================
# LIST VEHICLES
# ================================
class VehiclesLister
  def self.display
    vehicles = Vehicle.order(:vehicle_number)

    if vehicles.empty?
      puts 'No vehicles found.'
      return
    end

    puts '=' * 80
    puts 'Vehicles List'
    puts '=' * 80

    vehicles.each do |v|
      puts "• #{v.vehicle_number.ljust(15)} | #{v.vehicle_model}"
    end

    puts "\n#{vehicles.count} total vehicles"
  end
end

# ================================
# DELETE ALL VEHICLES
# ================================
class VehiclesDeleter
  def self.execute
    count = Vehicle.count

    if count.zero?
      puts 'No vehicles to delete.'
      return
    end

    puts "WARNING: This will delete all #{count} vehicles!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == 'yes'
      Vehicle.delete_all
      puts "✓ Deleted all #{count} vehicles"
    else
      puts 'Deletion cancelled.'
    end
  end
end
