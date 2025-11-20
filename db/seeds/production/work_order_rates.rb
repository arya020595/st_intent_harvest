# frozen_string_literal: true

# Production Seeds - Work Order Rates
# Create standardized rates for different work order types

puts '💰 Creating work order rates...'

# Fetch unit IDs once
units = Unit.pluck(:name, :id).to_h
day_unit_id = units['Day']
hectare_unit_id = units['Hectare']

# Define rate configurations
rates_data = [
  # Day-based rates
  { work_order_name: 'Harvesting', rate: 75.00, unit_id: day_unit_id },
  { work_order_name: 'Spraying', rate: 65.00, unit_id: day_unit_id },
  { work_order_name: 'Fertilizing', rate: 70.00, unit_id: day_unit_id },
  { work_order_name: 'Weeding', rate: 60.00, unit_id: day_unit_id },
  { work_order_name: 'Pruning', rate: 80.00, unit_id: day_unit_id },
  { work_order_name: 'Planting', rate: 85.00, unit_id: day_unit_id },

  # Hectare-based rates
  { work_order_name: 'Land Preparation', rate: 300.00, unit_id: hectare_unit_id },
  { work_order_name: 'Land Clearing', rate: 250.00, unit_id: hectare_unit_id },
  { work_order_name: 'Irrigation Setup', rate: 350.00, unit_id: hectare_unit_id }
]

# Batch insert rates
existing_rates = WorkOrderRate.pluck(:work_order_name)
new_rates = rates_data.reject { |r| existing_rates.include?(r[:work_order_name]) }

if new_rates.any?
  rates_insert_data = new_rates.map do |r|
    {
      work_order_name: r[:work_order_name],
      rate: r[:rate],
      unit_id: r[:unit_id],
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  WorkOrderRate.insert_all(rates_insert_data)
end

puts "✓ Created #{WorkOrderRate.count} work order rates"
