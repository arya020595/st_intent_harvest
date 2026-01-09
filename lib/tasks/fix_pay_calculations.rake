# frozen_string_literal: true

namespace :pay_calculations do
  # Shared helper methods for pay calculation tasks
  def calculate_active_earnings(worker_id, month_start, month_end)
    WorkOrderWorker
      .where(discarded_at: nil)
      .joins(:work_order)
      .where(worker_id: worker_id)
      .merge(WorkOrder.kept)
      .where(work_orders: {
               work_order_status: 'completed',
               completion_date: month_start..month_end,
               work_order_rate_type: %w[normal work_days]
             })
      .sum(:amount)
  end

  def recalculate_detail_gross_salary(detail, month_start, month_end)
    worker = detail.worker
    active_earnings = calculate_active_earnings(worker.id, month_start, month_end)
    old_gross = detail.gross_salary

    if old_gross != active_earnings
      detail.update!(gross_salary: active_earnings)
      detail.recalculate_deductions!
      puts "  Worker ##{worker.id} (#{worker.name}): #{old_gross} -> #{active_earnings}"
      true
    else
      detail.recalculate_deductions!
      puts "  Worker ##{worker.id} (#{worker.name}): No gross change (#{old_gross})"
      false
    end
  end

  def process_pay_calculation(pay_calc)
    month_date = Date.parse("#{pay_calc.month_year}-01")
    month_start = month_date.beginning_of_month
    month_end = month_date.end_of_month

    updated_count = 0
    pay_calc.pay_calculation_details.includes(:worker).find_each do |detail|
      recalculate_detail_gross_salary(detail, month_start, month_end)
      updated_count += 1
    rescue StandardError => e
      puts "  Error processing Worker ##{detail.worker&.id}: #{e.message}"
    end

    pay_calc.recalculate_overall_total!
    updated_count
  end

  desc 'Recalculate all pay calculation details (gross salary from kept work orders + deductions)'
  task recalculate_all: :environment do
    puts 'Starting recalculation of all pay calculation details...'

    PayCalculation.find_each do |pay_calc|
      puts "\n#{'=' * 60}"
      puts "Processing PayCalculation ##{pay_calc.id} (#{pay_calc.month_year})"
      puts '=' * 60

      process_pay_calculation(pay_calc)
      puts "Updated PayCalculation ##{pay_calc.id} totals"
    end

    puts "\n#{'=' * 60}"
    puts 'All done! ✓'
    puts '=' * 60
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

    puts '=' * 60
    puts "Recalculating pay calculation details for #{month_year}..."
    puts '=' * 60

    updated_count = process_pay_calculation(pay_calculation)

    puts "\n#{'=' * 60}"
    puts "Recalculation completed for #{month_year}"
    puts "Total records updated: #{updated_count}"
    puts "Total Gross Salary: RM #{pay_calculation.total_gross_salary}"
    puts "Total Deductions: RM #{pay_calculation.total_deductions}"
    puts "Total Net Salary: RM #{pay_calculation.total_net_salary}"
    puts '=' * 60
  end
end
