# frozen_string_literal: true

namespace :pay_calculation_details do
  desc 'Backfill block_id for existing pay_calculation_details'
  task backfill_block_id: :environment do
    puts 'Starting backfill of block_id for pay_calculation_details...'

    # Get all pay_calculation_details without a block_id
    details_without_block = PayCalculationDetail.where(block_id: nil).includes(:worker, :pay_calculation)

    total_count = details_without_block.count
    updated_count = 0
    skipped_count = 0

    puts "Found #{total_count} records to process"

    details_without_block.find_each.with_index do |detail, index|
      # Find the most common block for this worker in the pay calculation's month
      month_year = detail.pay_calculation.month_year
      # Convert month_year string (e.g., "2025-01") to first day of the month for comparison
      work_month_date = Date.parse("#{month_year}-01")

      # Get work_order_workers for this worker in the same month
      work_order_worker = WorkOrderWorker
                            .joins(:work_order)
                            .where(worker_id: detail.worker_id)
                            .where('work_orders.work_month = ?', work_month_date)
                            .select('work_orders.block_id, COUNT(*) as frequency')
                            .group('work_orders.block_id')
                            .order('frequency DESC')
                            .first

      if work_order_worker&.block_id
        detail.update_column(:block_id, work_order_worker.block_id)
        updated_count += 1
        puts "[#{index + 1}/#{total_count}] Updated PayCalculationDetail ##{detail.id} with block_id: #{work_order_worker.block_id}"
      else
        skipped_count += 1
        puts "[#{index + 1}/#{total_count}] Skipped PayCalculationDetail ##{detail.id} - no work orders found for worker ##{detail.worker_id} in #{month_year}"
      end

      # Show progress every 100 records
      puts "Progress: #{index + 1}/#{total_count} (#{((index + 1) * 100.0 / total_count).round(2)}%)" if (index + 1) % 100 == 0
    end

    puts "\n=== Backfill Complete ==="
    puts "Total processed: #{total_count}"
    puts "Updated: #{updated_count}"
    puts "Skipped (no work orders): #{skipped_count}"
  end
end
