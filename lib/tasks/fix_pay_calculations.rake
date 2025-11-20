# frozen_string_literal: true

namespace :pay_calculations do
  desc 'Recalculate all pay calculation details (employee and employer deductions)'
  task recalculate_all: :environment do
    puts 'Starting recalculation of all pay calculation details...'

    total_count = PayCalculationDetail.count
    updated_count = 0
    error_count = 0

    PayCalculationDetail.find_each.with_index do |detail, index|
      detail.recalculate_deductions!
      updated_count += 1

      puts "Progress: #{index + 1}/#{total_count} processed..." if ((index + 1) % 50).zero?
    rescue StandardError => e
      error_count += 1
      puts "Error processing PayCalculationDetail ID #{detail.id}: #{e.message}"
    end

    puts "\n#{'=' * 60}"
    puts 'Recalculation completed!'
    puts "Total records: #{total_count}"
    puts "Successfully updated: #{updated_count}"
    puts "Errors: #{error_count}"
    puts '=' * 60

    # Recalculate overall totals for all pay calculations
    puts "\nRecalculating overall totals for pay calculations..."
    PayCalculation.find_each do |pay_calc|
      pay_calc.recalculate_overall_total!
      puts "Updated PayCalculation ID #{pay_calc.id} (#{pay_calc.month_year})"
    end

    puts "\nAll done! ✓"
  end

  desc 'Recalculate pay calculation details for a specific month (format: YYYY-MM)'
  task :recalculate_month, [:month_year] => :environment do |_t, args|
    month_year = args[:month_year]

    unless month_year
      puts 'Error: Please provide month_year parameter (format: YYYY-MM)'
      puts 'Usage: rake pay_calculations:recalculate_month[2024-11]'
      exit 1
    end

    pay_calculation = PayCalculation.find_by(month_year: month_year)

    unless pay_calculation
      puts "Error: No pay calculation found for month #{month_year}"
      exit 1
    end

    puts "Recalculating pay calculation details for #{month_year}..."

    updated_count = 0
    pay_calculation.pay_calculation_details.each do |detail|
      detail.recalculate_deductions!
      updated_count += 1
      puts "Updated: Worker ID #{detail.worker_id} - #{detail.worker.name}"
    end

    # Recalculate overall total
    pay_calculation.recalculate_overall_total!

    puts "\n#{'=' * 60}"
    puts "Recalculation completed for #{month_year}"
    puts "Total records updated: #{updated_count}"
    puts "Total Gross Salary: RM #{pay_calculation.total_gross_salary}"
    puts "Total Deductions: RM #{pay_calculation.total_deductions}"
    puts "Total Net Salary: RM #{pay_calculation.total_net_salary}"
    puts '=' * 60
  end
end
