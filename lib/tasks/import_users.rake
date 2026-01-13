# frozen_string_literal: true

require 'csv'

# Users Import Rake Tasks
namespace :users do
  desc 'Import users from CSV'
  task :import, [:file_path] => :environment do |_t, args|
    importer = UsersImporter.new(args[:file_path])
    importer.import
  end

  desc 'Display sample CSV format'
  task :sample do
    UsersSampleFormatter.display
  end

  desc 'List all users'
  task list: :environment do
    UsersLister.display
  end

  desc 'Delete all users (dangerous!)'
  task delete_all: :environment do
    UsersDeleter.execute
  end
end

# ================================
# USERS IMPORTER
# ================================
class UsersImporter
  DEFAULT_CSV_PATH = Rails.root.join('db/master_data/master_data_users.csv').freeze

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
    puts "Importing users from #{file_path}"
    puts '=' * 80
  end

  def parse_rows
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      stats[:total] += 1
      UsersRowProcessor.new(row, stats).process
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
class UsersRowProcessor
  def initialize(row, stats)
    @row = row
    @stats = stats

    @name     = row[:name]&.strip
    @role     = row[:role]&.strip
    @email    = row[:email]&.strip&.downcase
    @password = row[:password]&.strip
  end

  def process
    return skip('name is missing') if name.blank?
    return skip('email is missing') if email.blank?
    return skip('password is missing') if password.blank?

    upsert_user
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation error on row #{stats[:total]}: #{e.message}"
    stats[:errors] += 1
  end

  private

  attr_reader :row, :stats, :name, :role, :email, :password

  def skip(reason)
    puts "⚠ Row #{stats[:total]} skipped: #{reason}"
    stats[:skipped] += 1
  end

  def find_role(role_name)
    return nil if role_name.blank?

    Role.find_by(name: role_name.strip)
  end

  def upsert_user
    role_record = find_role(role)

    if role_record.nil?
      puts "❌ Row #{stats[:total]} error: Role '#{role}' does not exist."
      stats[:errors] += 1
      return
    end

    user = User.find_by(email: email)

    if user
      user.update!(name: name, role: role_record, password: password)
      puts "Updated: #{email} (#{name}, #{role_record.name})"
      stats[:updated] += 1
    else
      User.create!(name: name, email: email, role: role_record, password: password)
      puts "✓ Created: #{email} (#{name}, #{role_record.name})"
      stats[:created] += 1
    end
  end
end

# ================================
# SAMPLE FORMATTER
# ================================
class UsersSampleFormatter
  def self.display
    puts 'Sample CSV format for users:'
    puts '=' * 80
    puts 'name,role,email,password'
    puts 'John Doe,Manager,john@example.com,securepassword123'
    puts 'Sarah Tan,Clerk,sarah@example.com,securepassword123'
    puts 'Michael Lee,Field Conductor,mlee@example.com,securepassword123'
    puts '=' * 80

    puts "\nCOLUMN DESCRIPTION:"
    puts ' name     - User full name (required)'
    puts " role     - Matches 'roles.name' in DB (required)"
    puts ' email    - Unique email (required)'
    puts ' password - User password (required)'
  end
end

# ================================
# LIST USERS
# ================================
class UsersLister
  def self.display
    users = User.includes(:role).order(:name)

    if users.empty?
      puts 'No users found.'
      return
    end

    puts '=' * 80
    puts 'Users List'
    puts '=' * 80

    users.each do |u|
      puts "• #{u.name.ljust(25)} | #{u.role&.name.to_s.ljust(15)} | #{u.email}"
    end

    puts "\n#{users.count} total users"
  end
end

# ================================
# DELETE ALL USERS
# ================================
class UsersDeleter
  def self.execute
    count = User.count

    if count.zero?
      puts 'No users to delete.'
      return
    end

    puts "WARNING: This will delete all #{count} users!"
    print "Type 'yes' to confirm: "
    confirm = $stdin.gets.chomp

    if confirm.downcase == 'yes'
      User.delete_all
      puts "✓ Deleted all #{count} users"
    else
      puts 'Deletion cancelled.'
    end
  end
end
