# frozen_string_literal: true

require 'csv'

# Worker Date-of-Birth Import Rake Tasks
# Upserts workers from the updated CSV: creates missing workers, updates existing ones.
namespace :workers do
  desc 'Upsert workers from updated CSV (creates missing, updates existing, sets date_of_birth)'
  task :import_dob, [:csv_file] => :environment do |_task, args|
    importer = WorkersDobImporter.new(args[:csv_file])
    importer.import
  end
end

# ================================
# WORKERS DOB IMPORTER
# ================================
class WorkersDobImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_workers_2026_updated.csv').freeze

  def initialize(csv_file = nil)
    @csv_path = csv_file.present? ? Pathname.new(csv_file) : DEFAULT_CSV_PATH
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

  attr_reader :stats

  def validate_file!
    return if File.exist?(@csv_path)

    puts "File not found: #{@csv_path}"
    exit 1
  end

  def header
    puts "Upserting workers from #{@csv_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(@csv_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      WorkersDobRowProcessor.new(row, stats).process
    rescue StandardError => e
      puts "Unexpected error on row #{stats[:total]}: #{e.message}"
      stats[:errors] += 1
    end
  end

  def summary
    puts '=' * 80
    puts 'IMPORT SUMMARY'
    puts " Total rows:  #{stats[:total]}"
    puts " Created:     #{stats[:created]}"
    puts " Updated:     #{stats[:updated]}"
    puts " Skipped:     #{stats[:skipped]}  (missing required fields)"
    puts " Errors:      #{stats[:errors]}"
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
# WORKER DOB ROW PROCESSOR
# ================================
class WorkersDobRowProcessor
  def initialize(row, stats)
    @row             = row
    @stats           = stats
    @worker_id       = row[:id]&.strip
    @name            = row[:name]&.strip
    @nationality     = row[:nationality]&.strip
    @gender          = row[:gender]&.strip
    @identity_number = row[:identity_number]&.strip
    @worker_type     = row[:worker_type]&.strip
    @position        = row[:position]&.strip
    @hired_date      = row[:hired_date]&.strip
    @is_active       = normalize_boolean(row[:is_active])
    @date_of_birth   = row[:date_of_birth]&.strip
  end

  def process
    return skip('worker ID is missing')   if worker_id.blank?
    return skip('name is missing')        if name.blank?
    return skip('nationality is missing') if nationality.blank?
    return skip('gender is missing')      if gender.blank?
    return skip('worker_type is missing') if worker_type.blank?

    worker = Worker.find_by(id: worker_id)

    if worker
      update_worker(worker)
    else
      create_worker
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "  Validation error on row #{stats[:total]} [ID #{worker_id}]: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :worker_id, :name, :nationality, :gender,
              :identity_number, :worker_type, :position, :hired_date,
              :is_active, :date_of_birth

  def update_worker(worker)
    worker.update!(
      name:            name,
      nationality:     nationality,
      gender:          gender,
      identity_number: identity_number,
      worker_type:     worker_type,
      position:        position,
      is_active:       is_active,
      date_of_birth:   parse_date(date_of_birth)
    )
    dob_label = date_of_birth.present? ? date_of_birth : 'no DOB'
    puts "✓ Updated:  [#{worker_id}] #{name} (#{dob_label})"
    stats[:updated] += 1
  end

  def create_worker
    Worker.create!(
      id:              worker_id,
      name:            name,
      nationality:     nationality,
      gender:          gender,
      identity_number: identity_number,
      worker_type:     worker_type,
      position:        position,
      hired_date:      parse_date(hired_date),
      is_active:       is_active,
      date_of_birth:   parse_date(date_of_birth)
    )
    dob_label = date_of_birth.present? ? date_of_birth : 'no DOB'
    puts "✓ Created:  [#{worker_id}] #{name} (#{dob_label})"
    stats[:created] += 1
  end

  def normalize_boolean(value)
    return false if value.nil?

    %w[true yes 1 t y].include?(value.to_s.strip.downcase)
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def skip(reason)
    puts "  Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end
end
