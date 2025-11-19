# frozen_string_literal: true

namespace :deductions do
  desc 'Update deduction type rate with new effective date'
  task :update_rate, %i[code employee_contribution employer_contribution effective_from] => :environment do |_t, args|
    code = args[:code]
    employee_contribution = args[:employee_contribution].to_f
    employer_contribution = args[:employer_contribution].to_f

    begin
      effective_from = Date.parse(args[:effective_from])
    rescue ArgumentError, TypeError
      puts 'Error: Invalid date format for effective_from'
      puts 'Usage: rake deductions:update_rate[EPF,11.00,12.00,2026-01-01]'
      exit 1
    end

    # Validate inputs
    unless code.present? && employee_contribution >= 0 && employer_contribution >= 0
      puts 'Error: Invalid arguments'
      puts 'Usage: rake deductions:update_rate[EPF,11.00,12.00,2026-01-01]'
      exit 1
    end

    ActiveRecord::Base.transaction do
      # Find current active deduction (no end date)
      current = DeductionType.find_by(code: code, effective_until: nil)

      unless current
        puts "Error: No active deduction found with code '#{code}'"
        exit 1
      end

      # Check if effective_from is in the future
      if effective_from <= Date.current
        puts "Warning: effective_from (#{effective_from}) is not in the future!"
        puts 'This will affect calculations starting from that date.'
        print 'Continue? (yes/no): '
        response = $stdin.gets.chomp
        exit unless response.downcase == 'yes'
      end

      # End the current rate (day before new rate starts)
      end_date = effective_from - 1.day
      current.update!(effective_until: end_date)

      # Create new rate with all required fields
      new_deduction = DeductionType.create!(
        code: code,
        name: current.name,
        description: "#{current.description} - Updated rate from #{effective_from}",
        employee_contribution: employee_contribution,
        employer_contribution: employer_contribution,
        calculation_type: current.calculation_type,
        applies_to_nationality: current.applies_to_nationality,
        is_active: true,
        effective_from: effective_from,
        effective_until: nil
      )

      puts "✓ Successfully updated #{code} deduction rate"
      puts "\nOld rate (#{current.effective_from} to #{end_date}):"
      puts "  Employee: #{current.employee_contribution}% | Employer: #{current.employer_contribution}%"
      puts "\nNew rate (#{effective_from} onwards):"
      puts "  Employee: #{new_deduction.employee_contribution}% | Employer: #{new_deduction.employer_contribution}%"
    rescue ActiveRecord::RecordInvalid => e
      puts 'Error: Failed to update deduction rate'
      puts e.message
      exit 1
    end
  end

  desc 'Show deduction rate history for a code'
  task :history, [:code] => :environment do |_t, args|
    code = args[:code]

    unless code.present?
      puts 'Error: Please provide a deduction code'
      puts 'Usage: rake deductions:history[EPF]'
      exit 1
    end

    deductions = DeductionType.where(code: code).order(:effective_from)

    if deductions.empty?
      puts "No deductions found with code '#{code}'"
      exit
    end

    puts "=== Deduction Rate History for #{code} ==="
    deductions.each do |d|
      status = d.effective_until.nil? ? 'CURRENT' : 'PAST'
      puts "\n[#{status}] #{d.effective_from} to #{d.effective_until || 'present'}"
      puts "  Employee: #{d.employee_contribution}% | Employer: #{d.employer_contribution}%"
      puts "  Type: #{d.calculation_type} | Nationality: #{d.applies_to_nationality || 'all'}"
      puts "  Active: #{d.is_active}"
      puts "  Description: #{d.description}"
    end
  end

  desc 'Show what deductions are active for a specific month'
  task :active_for_month, [:month_year] => :environment do |_t, args|
    month_year = args[:month_year] || Date.current.strftime('%Y-%m')

    begin
      target_date = Date.parse("#{month_year}-01")
    rescue ArgumentError
      puts 'Error: Invalid month format'
      puts 'Usage: rake deductions:active_for_month[2026-01]'
      exit 1
    end

    deductions = DeductionType.active_on(target_date)

    puts "=== Deductions Active for #{month_year} ==="
    if deductions.empty?
      puts 'No active deductions found for this month'
    else
      # Group by nationality
      by_nationality = deductions.group_by { |d| d.applies_to_nationality || 'all' }

      by_nationality.each do |nationality, deds|
        puts "\n#{nationality.upcase}:"
        deds.each do |d|
          puts "  #{d.code} - #{d.name}"
          puts "    Employee: #{d.employee_contribution}% | Employer: #{d.employer_contribution}%"
          puts "    Type: #{d.calculation_type}"
        end
      end

      # Show percentage totals
      percentage_deds = deductions.where(calculation_type: 'percentage')
      total_employee_pct = percentage_deds.sum(:employee_contribution)
      total_employer_pct = percentage_deds.sum(:employer_contribution)

      puts "\nTotal Percentage Rates:"
      puts "  Employee: #{total_employee_pct}%"
      puts "  Employer: #{total_employer_pct}%"
    end
  end

  desc 'Create a new deduction type'
  task :create,
       %i[code name calculation_type employee_contribution employer_contribution nationality effective_from
          description] => :environment do |_t, args|
    code = args[:code]
    name = args[:name]
    calculation_type = args[:calculation_type]
    employee_contribution = args[:employee_contribution].to_f
    employer_contribution = args[:employer_contribution].to_f
    nationality = args[:nationality] || 'all'

    begin
      effective_from = args[:effective_from] ? Date.parse(args[:effective_from]) : Date.current
    rescue ArgumentError
      puts 'Error: Invalid date format for effective_from'
      puts 'Usage: rake deductions:create[TAX,"Income Tax",percentage,5.00,0.00,all,2026-01-01,"Monthly income tax"]'
      exit 1
    end

    description = args[:description] || name

    # Validate required fields
    if code.blank? || name.blank?
      puts 'Error: Code and name are required'
      puts 'Usage: rake deductions:create[TAX,"Income Tax",percentage,5.00,0.00,all,2026-01-01,"Monthly income tax"]'
      exit 1
    end

    # Validate calculation_type
    unless DeductionType::CALCULATION_TYPES.include?(calculation_type)
      puts "Error: Invalid calculation_type '#{calculation_type}'"
      puts "Must be one of: #{DeductionType::CALCULATION_TYPES.join(', ')}"
      exit 1
    end

    # Validate nationality
    unless DeductionType::NATIONALITY_TYPES.include?(nationality)
      puts "Error: Invalid nationality '#{nationality}'"
      puts "Must be one of: #{DeductionType::NATIONALITY_TYPES.join(', ')}"
      exit 1
    end

    # Check if code already exists
    existing = DeductionType.find_by(code: code, effective_until: nil)
    if existing
      puts "Error: Deduction with code '#{code}' already exists and is active"
      puts 'Use deductions:update_rate to change rates'
      exit 1
    end

    begin
      deduction = DeductionType.create!(
        code: code,
        name: name,
        description: description,
        calculation_type: calculation_type,
        employee_contribution: employee_contribution,
        employer_contribution: employer_contribution,
        applies_to_nationality: nationality,
        is_active: true,
        effective_from: effective_from,
        effective_until: nil
      )

      puts "✓ Successfully created #{code} deduction"
      puts "  Employee: #{deduction.employee_contribution}% | Employer: #{deduction.employer_contribution}%"
      puts "  Type: #{deduction.calculation_type}"
      puts "  Nationality: #{deduction.applies_to_nationality}"
      puts "  Effective from: #{deduction.effective_from}"
    rescue ActiveRecord::RecordInvalid => e
      puts 'Error: Failed to create deduction type'
      puts e.message
      exit 1
    end
  end
end
