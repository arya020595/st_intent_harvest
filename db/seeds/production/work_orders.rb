# frozen_string_literal: true

# Production Seeds - Work Orders
# Create work orders with workers and items

puts '📋 Creating work orders...'

# Fetch references once with optimized queries
blocks = Block.order(:id).to_a
work_order_rates = WorkOrderRate.order(:id).to_a
conductor_user = User.find_by(email: 'conductor@example.com')
manager_user = User.find_by(email: 'manager@example.com')
workers = Worker.where(is_active: true).order(:id).to_a
inventories = Inventory.includes(:unit, :category).order(:id).to_a

# Define work order configurations
# Using January 2025 to match PayCalculation month for worker_detail queries
work_orders_data = [
  { block: blocks[0], work_order_rate: work_order_rates[0], start_date: Date.new(2025, 1, 5), status: 'completed' },
  { block: blocks[1], work_order_rate: work_order_rates[1], start_date: Date.new(2025, 1, 8), status: 'completed' },
  { block: blocks[2], work_order_rate: work_order_rates[2], start_date: Date.new(2025, 1, 11), status: 'ongoing' },
  { block: blocks[3], work_order_rate: work_order_rates[3], start_date: Date.new(2025, 1, 14), status: 'pending' },
  { block: blocks[4], work_order_rate: work_order_rates[4], start_date: Date.new(2025, 1, 17), status: 'completed' },
  { block: blocks[5], work_order_rate: work_order_rates[5], start_date: Date.new(2025, 1, 20), status: 'ongoing' },
  { block: blocks[6], work_order_rate: work_order_rates[0], start_date: Date.new(2025, 1, 23),
    status: 'amendment_required' },
  { block: blocks[7], work_order_rate: work_order_rates[1], start_date: Date.new(2025, 1, 26), status: 'pending' },
  { block: blocks[8], work_order_rate: work_order_rates[2], start_date: Date.new(2025, 1, 28), status: 'ongoing' },
  { block: blocks[9], work_order_rate: work_order_rates[3], start_date: Date.new(2025, 1, 30), status: 'pending' }
]

# Create work orders
created_work_orders = []
work_orders_data.each do |data|
  wo = WorkOrder.find_or_create_by!(block_id: data[:block].id, start_date: data[:start_date]) do |work_order|
    # Assign association for validation, then denormalized fields
    if data[:work_order_rate]
      work_order.work_order_rate = data[:work_order_rate]
      if data[:work_order_rate].respond_to?(:unit)
        work_order.work_order_rate_unit_name = data[:work_order_rate].unit.name if data[:work_order_rate].unit
      elsif data[:work_order_rate].respond_to?(:unit_name)
        work_order.work_order_rate_unit_name = data[:work_order_rate].unit_name
      end

      if data[:work_order_rate].respond_to?(:work_order_rate_type)
        work_order.work_order_rate_type = data[:work_order_rate].work_order_rate_type
      end

      if data[:work_order_rate].respond_to?(:work_order_name)
        work_order.work_order_rate_name = data[:work_order_rate].work_order_name
      elsif data[:work_order_rate].respond_to?(:name)
        work_order.work_order_rate_name = data[:work_order_rate].name
      end

      if data[:work_order_rate].respond_to?(:rate)
        work_order.work_order_rate_price = data[:work_order_rate].rate
      elsif data[:work_order_rate].respond_to?(:price)
        work_order.work_order_rate_price = data[:work_order_rate].price
      end
    end

    if data[:block]
      work_order.block_number = data[:block].number if data[:block].respond_to?(:number)
      work_order.block_hectarage = data[:block].hectarage if data[:block].respond_to?(:hectarage)
    end
    work_order.work_order_status = data[:status]
    work_order.field_conductor_id = conductor_user.id
    work_order.field_conductor_name = conductor_user.name

    # Set work_month to the first day of the month for Mandays calculation
    work_order.work_month = data[:start_date].beginning_of_month if data[:start_date]

    work_order.created_at = data[:start_date]
    work_order.updated_at = data[:start_date]

    # Add approval info for completed work orders
    if data[:status] == 'completed'
      work_order.approved_by = manager_user.name
      work_order.approved_at = data[:start_date] + 7.days
    end
  end
  created_work_orders << wo
end

puts "  ✓ #{WorkOrder.count} work orders"

# ========== Work Order Workers ==========
puts '  • Work order workers...'

work_order_workers_data = [
  # Work Order 1 - 3 workers
  { work_order: created_work_orders[0], worker: workers[0], rate: 75.00, days: 5 },
  { work_order: created_work_orders[0], worker: workers[1], rate: 75.00, days: 5 },
  { work_order: created_work_orders[0], worker: workers[2], rate: 75.00, days: 4 },

  # Work Order 2 - 4 workers
  { work_order: created_work_orders[1], worker: workers[3], rate: 65.00, days: 6 },
  { work_order: created_work_orders[1], worker: workers[4], rate: 65.00, days: 6 },
  { work_order: created_work_orders[1], worker: workers[5], rate: 65.00, days: 5 },
  { work_order: created_work_orders[1], worker: workers[6], rate: 65.00, days: 5 },

  # Work Order 3 - 3 workers
  { work_order: created_work_orders[2], worker: workers[7], rate: 70.00, days: 4 },
  { work_order: created_work_orders[2], worker: workers[8], rate: 70.00, days: 4 },
  { work_order: created_work_orders[2], worker: workers[9], rate: 70.00, days: 3 },

  # Work Order 4 - 2 workers
  { work_order: created_work_orders[3], worker: workers[10], rate: 60.00, days: 5 },
  { work_order: created_work_orders[3], worker: workers[11], rate: 60.00, days: 5 },

  # Work Order 5 - 4 workers
  { work_order: created_work_orders[4], worker: workers[12], rate: 80.00, days: 6 },
  { work_order: created_work_orders[4], worker: workers[13], rate: 80.00, days: 6 },
  { work_order: created_work_orders[4], worker: workers[14], rate: 80.00, days: 5 },
  { work_order: created_work_orders[4], worker: workers[15], rate: 80.00, days: 5 },

  # Work Order 6 - 3 workers
  { work_order: created_work_orders[5], worker: workers[16], rate: 85.00, days: 4 },
  { work_order: created_work_orders[5], worker: workers[17], rate: 85.00, days: 4 },
  { work_order: created_work_orders[5], worker: workers[18], rate: 85.00, days: 3 },

  # Work Order 7 - 2 workers
  { work_order: created_work_orders[6], worker: workers[19], rate: 70.00, days: 5 },
  { work_order: created_work_orders[6], worker: workers[20], rate: 70.00, days: 5 },

  # Work Order 8 - 3 workers
  { work_order: created_work_orders[7], worker: workers[21], rate: 75.00, days: 4 },
  { work_order: created_work_orders[7], worker: workers[22], rate: 75.00, days: 4 },
  { work_order: created_work_orders[7], worker: workers[23], rate: 75.00, days: 3 },

  # Work Order 9 - 3 workers
  { work_order: created_work_orders[8], worker: workers[24], rate: 80.00, days: 6 },
  { work_order: created_work_orders[8], worker: workers[25], rate: 80.00, days: 6 },
  { work_order: created_work_orders[8], worker: workers[26], rate: 80.00, days: 5 },

  # Work Order 10 - 3 workers (reuse some workers)
  { work_order: created_work_orders[9], worker: workers[0], rate: 65.00, days: 5 },
  { work_order: created_work_orders[9], worker: workers[1], rate: 65.00, days: 5 },
  { work_order: created_work_orders[9], worker: workers[2], rate: 65.00, days: 4 }
]

# Batch insert work order workers
existing_wow = WorkOrderWorker.pluck(:work_order_id, :worker_id).to_set
new_wow = work_order_workers_data.reject do |data|
  existing_wow.include?([data[:work_order].id, data[:worker].id])
end

if new_wow.any?
  wow_insert_data = new_wow.map do |data|
    attrs = {
      work_order_id: data[:work_order].id,
      worker_id: data[:worker].id,
      worker_name: data[:worker].name,
      rate: data[:rate],
      amount: data[:rate] * data[:days],
      created_at: Time.current,
      updated_at: Time.current
    }
    # Set days or quantity based on work order type
    case data[:work_order].work_order_rate_type
    when 'work_days'
      attrs[:work_days] = data[:days]
      attrs[:remarks] = "#{data[:days]} days worked"
    else
      attrs[:work_area_size] = data[:days] # treat as quantity for normal type
      attrs[:remarks] = "#{data[:days]} Ha worked"
    end
    attrs
  end
  WorkOrderWorker.insert_all(wow_insert_data)
end

puts "    ✓ #{WorkOrderWorker.count} work order workers"

# ========== Work Order Items ==========
puts '  • Work order items...'

work_order_items_data = [
  # Work Order 1 items
  { work_order: created_work_orders[0], inventory: inventories[0], amount_used: 50 },
  { work_order: created_work_orders[0], inventory: inventories[9], amount_used: 10 },

  # Work Order 2 items
  { work_order: created_work_orders[1], inventory: inventories[5], amount_used: 30 },
  { work_order: created_work_orders[1], inventory: inventories[13], amount_used: 5 },

  # Work Order 3 items
  { work_order: created_work_orders[2], inventory: inventories[1], amount_used: 40 },
  { work_order: created_work_orders[2], inventory: inventories[10], amount_used: 8 },
  { work_order: created_work_orders[2], inventory: inventories[14], amount_used: 3 },

  # Work Order 4 items
  { work_order: created_work_orders[3], inventory: inventories[11], amount_used: 6 },

  # Work Order 5 items
  { work_order: created_work_orders[4], inventory: inventories[2], amount_used: 45 },
  { work_order: created_work_orders[4], inventory: inventories[12], amount_used: 7 },

  # Work Order 6 items
  { work_order: created_work_orders[5], inventory: inventories[3], amount_used: 35 },
  { work_order: created_work_orders[5], inventory: inventories[15], amount_used: 4 },

  # Work Order 7 items
  { work_order: created_work_orders[6], inventory: inventories[4], amount_used: 40 },

  # Work Order 8 items
  { work_order: created_work_orders[7], inventory: inventories[6], amount_used: 25 },
  { work_order: created_work_orders[7], inventory: inventories[16], amount_used: 5 },

  # Work Order 9 items
  { work_order: created_work_orders[8], inventory: inventories[7], amount_used: 30 },

  # Work Order 10 items
  { work_order: created_work_orders[9], inventory: inventories[8], amount_used: 20 },
  { work_order: created_work_orders[9], inventory: inventories[17], amount_used: 3 }
]

# Batch insert work order items
existing_woi = WorkOrderItem.pluck(:work_order_id, :inventory_id).to_set
new_woi = work_order_items_data.reject do |data|
  existing_woi.include?([data[:work_order].id, data[:inventory].id])
end

if new_woi.any?
  woi_insert_data = new_woi.map do |data|
    {
      work_order_id: data[:work_order].id,
      inventory_id: data[:inventory].id,
      item_name: data[:inventory].name,
      amount_used: data[:amount_used],
      price: data[:inventory].price,
      unit_name: data[:inventory].unit.name,
      category_name: data[:inventory].category.name,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  WorkOrderItem.insert_all(woi_insert_data)
end

puts "    ✓ #{WorkOrderItem.count} work order items"

puts '✓ Work orders with relationships created'
