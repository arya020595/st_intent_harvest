# frozen_string_literal: true

# Production Seeds - Master Data
# Create Units, Categories, Blocks, Vehicles, and Deduction Types

puts '📊 Creating master data...'

# ========== Units ==========
puts '  • Units...'
units_data = [
  { name: 'Kg', unit_type: 'Weight' },
  { name: 'Liter', unit_type: 'Volume' },
  { name: 'Piece', unit_type: 'Count' },
  { name: 'Hour', unit_type: 'Time' },
  { name: 'Day', unit_type: 'Time' },
  { name: 'Hectare', unit_type: 'Area' },
  { name: 'Ton', unit_type: 'Weight' }
]

units_data.each do |unit_data|
  Unit.find_or_create_by!(name: unit_data[:name]) do |unit|
    unit.unit_type = unit_data[:unit_type]
  end
end

puts "    ✓ #{Unit.count} units"

# ========== Categories ==========
puts '  • Categories...'
categories_data = [
  { name: 'Material', category_type: 'Material' },
  { name: 'Fertilizer', category_type: 'Supply' },
  { name: 'Pesticide', category_type: 'Supply' },
  { name: 'Tools', category_type: 'Equipment' },
  { name: 'Equipment', category_type: 'Equipment' }
]

categories_data.each do |cat_data|
  Category.find_or_create_by!(name: cat_data[:name]) do |category|
    category.category_type = cat_data[:category_type]
  end
end

puts "    ✓ #{Category.count} categories"

# ========== Blocks ==========
puts '  • Blocks...'
blocks_data = [
  { block_number: 'BLK-001', hectarage: 15.50 },
  { block_number: 'BLK-002', hectarage: 22.30 },
  { block_number: 'BLK-003', hectarage: 18.75 },
  { block_number: 'BLK-004', hectarage: 30.00 },
  { block_number: 'BLK-005', hectarage: 12.40 },
  { block_number: 'BLK-006', hectarage: 25.60 },
  { block_number: 'BLK-007', hectarage: 19.80 },
  { block_number: 'BLK-008', hectarage: 28.90 },
  { block_number: 'BLK-009', hectarage: 16.20 },
  { block_number: 'BLK-010', hectarage: 21.50 }
]

# Batch insert blocks
existing_blocks = Block.pluck(:block_number)
new_blocks = blocks_data.reject { |b| existing_blocks.include?(b[:block_number]) }

if new_blocks.any?
  blocks_insert_data = new_blocks.map do |b|
    { block_number: b[:block_number], hectarage: b[:hectarage], created_at: Time.current, updated_at: Time.current }
  end
  Block.insert_all(blocks_insert_data)
end

puts "    ✓ #{Block.count} blocks"

# ========== Vehicles ==========
puts '  • Vehicles...'
vehicles_data = [
  { vehicle_number: 'VH-001', vehicle_model: 'Toyota Hilux' },
  { vehicle_number: 'VH-002', vehicle_model: 'Isuzu D-Max' },
  { vehicle_number: 'VH-003', vehicle_model: 'Mitsubishi Triton' },
  { vehicle_number: 'VH-004', vehicle_model: 'Ford Ranger' },
  { vehicle_number: 'VH-005', vehicle_model: 'Nissan Navara' },
  { vehicle_number: 'VH-006', vehicle_model: 'Mazda BT-50' },
  { vehicle_number: 'VH-007', vehicle_model: 'Chevrolet Colorado' },
  { vehicle_number: 'VH-008', vehicle_model: 'Toyota Hilux' },
  { vehicle_number: 'VH-009', vehicle_model: 'Isuzu D-Max' },
  { vehicle_number: 'VH-010', vehicle_model: 'Mitsubishi Triton' }
]

# Batch insert vehicles
existing_vehicles = Vehicle.pluck(:vehicle_number)
new_vehicles = vehicles_data.reject { |v| existing_vehicles.include?(v[:vehicle_number]) }

if new_vehicles.any?
  vehicles_insert_data = new_vehicles.map do |v|
    { vehicle_number: v[:vehicle_number], vehicle_model: v[:vehicle_model], created_at: Time.current,
      updated_at: Time.current }
  end
  Vehicle.insert_all(vehicles_insert_data)
end

puts "    ✓ #{Vehicle.count} vehicles"

puts '✓ Master data created'
