# frozen_string_literal: true

require 'csv'

# Workers Import Rake Tasks
namespace :workers do
  desc 'Import workers from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = WorkersImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV format'
  task :sample do
    WorkersSampleFormatter.display
  end

  desc 'List all workers'
  task list: :environment do
    WorkersLister.display
  end

  desc 'Delete all workers (dangerous!)'
  task delete_all: :environment do
    WorkersDeleter.execute
  end
end

# ================================
# WORKERS IMPORTER
# ================================
class WorkersImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_workers.csv').freeze

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
    puts "Importing workers from #{file_path}"
    puts "=" * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      WorkersRowProcessor.new(row, stats).process
    rescue StandardError => e
      puts "Unexpected error on row #{stats[:total]}: #{e.message}"
      stats[:errors] += 1
    end
  end

  def summary
    puts "=" * 80
    puts "IMPORT SUMMARY"
    puts " Total rows: #{stats[:total]}"
    puts " Created:    #{stats[:created]}"
    puts " Updated:    #{stats[:updated]}"
    puts " Skipped:    #{stats[:skipped]}"
    puts " Errors:     #{stats[:errors]}"
    puts "=" * 80

    if stats[:errors].zero?
      puts "✓ Import completed successfully."
    else
      puts "⚠ Import completed with errors."
    end
  end

  def abort_transaction(error)
    puts "Transaction rolled back: #{error.message}"
    raise ActiveRecord::Rollback
  end
end

# ================================
# WORKER ROW PROCESSOR
# ================================
class WorkersRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @name = row[:name]&.strip
    @nationality = row[:nationality]&.strip
    @gender = row[:gender]&.strip
    @identity_number = row[:identity_number]&.strip
    @worker_type = row[:worker_type]&.strip
  end

  def process
    return skip("name is missing") if name.blank?
    return skip("nationality is missing") if nationality.blank?
    return skip("gender is missing") if gender.blank?
    return skip("worker_type is missing") if worker_type.blank?

    upsert_worker
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :name, :nationality, :gender, :identity_number, :worker_type

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  # Upsert using composite key: name + nationality + gender
  def upsert_worker
    worker = Worker.find_by(name: name, nationality: nationality, gender: gender)

    if worker
      worker.update!(identity_number: identity_number, worker_type: worker_type)
      puts "Updated: #{name} (#{worker_type})"
      stats[:updated] += 1
    else
      Worker.create!(name: name, nationality: nationality, gender: gender, identity_number: identity_number, worker_type: worker_type)
      puts "✓ Created: #{name} (#{worker_type})"
      stats[:created] += 1
    end
  end
end

# ================================
# SAMPLE FORMATTER
# ================================
class WorkersSampleFormatter
  def self.display
    puts "Sample CSV format for workers:"
    puts "=" * 80
    puts "name,nationality,gender,identity_number,worker_type"
    puts "John Doe,Local,Male,830310126331,Full - Time"
    puts "Jane Smith,Foreigner,Female,X5490686,Part - Time"
    puts "=" * 80

    puts "\nCOLUMN DESCRIPTION:"
    puts " name            - Worker full name (required)"
    puts " nationality     - Local/Foreigner/Foreigner (No Passport) (required)"
    puts " gender          - Male/Female (required)"
    puts " identity_number - Unique ID or passport (optional for 'SMART SABAH')"
    puts " worker_type     - Full - Time / Part - Time (required)"
  end
end

# ================================
# LIST WORKERS
# ================================
class WorkersLister
  def self.display
    workers = Worker.order(:name)

    if workers.empty?
      puts "No workers found."
      return
    end

    puts "=" * 80
    puts "Workers List"
    puts "=" * 80

    workers.each do |w|
      puts "• #{w.name.ljust(25)} | #{w.nationality.ljust(20)} | #{w.gender.ljust(6)} | #{w.identity_number.to_s.ljust(15)} | #{w.worker_type}"
    end

    puts "\n#{workers.count} total workers"
  end
end

# ================================
# DELETE ALL WORKERS
# ================================
class WorkersDeleter
  def self.execute
    count = Worker.count

    if count.zero?
      puts "No workers to delete."
      return
    end

    puts "WARNING: This will delete all #{count} workers!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == "yes"
      Worker.delete_all
      puts "✓ Deleted all #{count} workers"
    else
      puts "Deletion cancelled."
    end
  end
end
