# frozen_string_literal: true

# Production Seeds - Inventories
# Create inventory items across different categories

puts '📦 Creating inventories...'

# Fetch references once with optimized queries
units = Unit.pluck(:name, :id).to_h
categories = Category.pluck(:name, :id).to_h

# Define inventory data grouped by category
inventory_data = {
  'Fertilizer' => [
    { name: 'NPK Fertilizer', stock_quantity: 250, unit: 'Kg', price: 65.00, supplier: 'PT Pupuk Indonesia' },
    { name: 'Organic Fertilizer', stock_quantity: 180, unit: 'Kg', price: 55.00, supplier: 'CV Organik Jaya' },
    { name: 'Urea Fertilizer', stock_quantity: 320, unit: 'Kg', price: 70.00, supplier: 'PT Pupuk Indonesia' },
    { name: 'Compost', stock_quantity: 150, unit: 'Kg', price: 45.00, supplier: 'CV Organik Jaya' },
    { name: 'Phosphate Fertilizer', stock_quantity: 200, unit: 'Kg', price: 75.00, supplier: 'PT Pupuk Indonesia' }
  ],
  'Pesticide' => [
    { name: 'Herbicide', stock_quantity: 120, unit: 'Liter', price: 45.00, supplier: 'PT Agro Kimia' },
    { name: 'Insecticide', stock_quantity: 95, unit: 'Liter', price: 50.00, supplier: 'PT Agro Kimia' },
    { name: 'Fungicide', stock_quantity: 110, unit: 'Liter', price: 48.00, supplier: 'CV Pestisida Nusantara' },
    { name: 'Pesticide Mix', stock_quantity: 85, unit: 'Liter', price: 55.00, supplier: 'PT Agro Kimia' }
  ],
  'Tools' => [
    { name: 'Harvesting Knife', stock_quantity: 50, unit: 'Piece', price: 25.00, supplier: 'Toko Alat Tani' },
    { name: 'Pruning Shears', stock_quantity: 40, unit: 'Piece', price: 35.00, supplier: 'Toko Alat Tani' },
    { name: 'Hand Trowel', stock_quantity: 60, unit: 'Piece', price: 18.00, supplier: 'CV Perkakas Pertanian' },
    { name: 'Garden Hoe', stock_quantity: 45, unit: 'Piece', price: 30.00, supplier: 'Toko Alat Tani' },
    { name: 'Machete', stock_quantity: 35, unit: 'Piece', price: 40.00, supplier: 'CV Perkakas Pertanian' }
  ],
  'Equipment' => [
    { name: 'Sprayer Machine', stock_quantity: 8, unit: 'Piece', price: 1500.00, supplier: 'PT Mesin Pertanian' },
    { name: 'Water Pump', stock_quantity: 6, unit: 'Piece', price: 1200.00, supplier: 'CV Teknik Jaya' },
    { name: 'Generator', stock_quantity: 5, unit: 'Piece', price: 2000.00, supplier: 'PT Mesin Pertanian' },
    { name: 'Lawn Mower', stock_quantity: 7, unit: 'Piece', price: 1800.00, supplier: 'CV Teknik Jaya' }
  ]
}

# Get existing inventory names to avoid duplicates
existing_inventories = Inventory.pluck(:name)
all_items = []

inventory_data.each do |category_name, items|
  category_id = categories[category_name]

  items.each do |item|
    next if existing_inventories.include?(item[:name])

    unit_id = units[item[:unit]]
    input_date = Date.current - rand(30..180).days

    all_items << {
      name: item[:name],
      stock_quantity: item[:stock_quantity],
      category_id: category_id,
      unit_id: unit_id,
      price: item[:price],
      supplier: item[:supplier],
      input_date: input_date,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

# Batch insert all inventories
Inventory.insert_all(all_items) if all_items.any?

puts "✓ Created #{Inventory.count} inventory items"
