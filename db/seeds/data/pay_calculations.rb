# frozen_string_literal: true

# Seeds - Pay Calculations
# Process completed work orders to generate pay calculations and details

puts '💵 Processing pay calculations from completed work orders...'

# Get all completed work orders (AASM column is work_order_status)
completed_work_orders = WorkOrder.where(work_order_status: 'completed')

if completed_work_orders.any?
  completed_work_orders.each do |work_order|
    # Use the service to process pay calculation for each completed work order
    result = PayCalculationServices::ProcessWorkOrderService.new(work_order).call

    if result.success?
      print '.'
    else
      print 'x'
      puts "\n  ⚠ #{work_order.id}: #{result.failure}" if result.failure?
    end
  end
  puts ''

  pay_calc_count = PayCalculation.count
  detail_count = PayCalculationDetail.count
  puts "✓ Processed #{completed_work_orders.count} completed work orders"
  puts "  → Created #{pay_calc_count} pay calculation(s) with #{detail_count} worker details"
else
  puts 'ℹ No completed work orders to process'
end
