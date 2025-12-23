# frozen_string_literal: true

# Seeds - Inventories
# Create inventory items across different categories
# Inventory model now stores items, with stock tracked via InventoryOrder

puts '📦 Creating inventories...'

# Fetch references once with optimized queries
units = Unit.pluck(:name, :id).to_h
categories = Category.pluck(:name, :id).to_h

# Define inventory data grouped by category
# Stock data will be created via InventoryOrders (multiple orders per item for realistic history)
inventory_data = {
  'Fertilizer' => [
    { name: 'NPK Fertilizer', unit: 'Kg', orders: [
      { quantity: 250, total_price: 16_250.00, supplier: 'PT Pupuk Indonesia', days_ago: 120 },
      { quantity: 150, total_price: 9750.00, supplier: 'PT Pupuk Indonesia', days_ago: 60 },
      { quantity: 100, total_price: 6700.00, supplier: 'CV Tani Makmur', days_ago: 15 }
    ] },
    { name: 'Organic Fertilizer', unit: 'Kg', orders: [
      { quantity: 180, total_price: 9900.00, supplier: 'CV Organik Jaya', days_ago: 90 },
      { quantity: 200, total_price: 11_000.00, supplier: 'CV Organik Jaya', days_ago: 30 }
    ] },
    { name: 'Urea Fertilizer', unit: 'Kg', orders: [
      { quantity: 320, total_price: 22_400.00, supplier: 'PT Pupuk Indonesia', days_ago: 150 },
      { quantity: 180, total_price: 12_600.00, supplier: 'PT Pupuk Indonesia', days_ago: 45 }
    ] },
    { name: 'Compost', unit: 'Kg', orders: [
      { quantity: 150, total_price: 6750.00, supplier: 'CV Organik Jaya', days_ago: 100 },
      { quantity: 100, total_price: 4500.00, supplier: 'CV Organik Jaya', days_ago: 20 }
    ] },
    { name: 'Phosphate Fertilizer', unit: 'Kg', orders: [
      { quantity: 200, total_price: 15_000.00, supplier: 'PT Pupuk Indonesia', days_ago: 80 }
    ] }
  ],
  'Pesticide' => [
    { name: 'Herbicide', unit: 'Liter', orders: [
      { quantity: 120, total_price: 5400.00, supplier: 'PT Agro Kimia', days_ago: 110 },
      { quantity: 80, total_price: 3600.00, supplier: 'PT Agro Kimia', days_ago: 40 }
    ] },
    { name: 'Insecticide', unit: 'Liter', orders: [
      { quantity: 95, total_price: 4750.00, supplier: 'PT Agro Kimia', days_ago: 75 },
      { quantity: 60, total_price: 3000.00, supplier: 'CV Pestisida Nusantara', days_ago: 25 }
    ] },
    { name: 'Fungicide', unit: 'Liter', orders: [
      { quantity: 110, total_price: 5280.00, supplier: 'CV Pestisida Nusantara', days_ago: 95 }
    ] },
    { name: 'Pesticide Mix', unit: 'Liter', orders: [
      { quantity: 85, total_price: 4675.00, supplier: 'PT Agro Kimia', days_ago: 65 },
      { quantity: 50, total_price: 2750.00, supplier: 'PT Agro Kimia', days_ago: 10 }
    ] }
  ],
  'Tools' => [
    { name: 'Harvesting Knife', unit: 'Piece', orders: [
      { quantity: 50, total_price: 1250.00, supplier: 'Toko Alat Tani', days_ago: 180 },
      { quantity: 30, total_price: 750.00, supplier: 'Toko Alat Tani', days_ago: 60 }
    ] },
    { name: 'Pruning Shears', unit: 'Piece', orders: [
      { quantity: 40, total_price: 1400.00, supplier: 'Toko Alat Tani', days_ago: 140 }
    ] },
    { name: 'Hand Trowel', unit: 'Piece', orders: [
      { quantity: 60, total_price: 1080.00, supplier: 'CV Perkakas Pertanian', days_ago: 160 },
      { quantity: 40, total_price: 720.00, supplier: 'CV Perkakas Pertanian', days_ago: 50 }
    ] },
    { name: 'Garden Hoe', unit: 'Piece', orders: [
      { quantity: 45, total_price: 1350.00, supplier: 'Toko Alat Tani', days_ago: 130 }
    ] },
    { name: 'Machete', unit: 'Piece', orders: [
      { quantity: 35, total_price: 1400.00, supplier: 'CV Perkakas Pertanian', days_ago: 170 },
      { quantity: 20, total_price: 800.00, supplier: 'CV Perkakas Pertanian', days_ago: 35 }
    ] }
  ],
  'Equipment' => [
    { name: 'Sprayer Machine', unit: 'Piece', orders: [
      { quantity: 8, total_price: 12_000.00, supplier: 'PT Mesin Pertanian', days_ago: 200 },
      { quantity: 4, total_price: 6000.00, supplier: 'PT Mesin Pertanian', days_ago: 45 }
    ] },
    { name: 'Water Pump', unit: 'Piece', orders: [
      { quantity: 6, total_price: 7200.00, supplier: 'CV Teknik Jaya', days_ago: 180 }
    ] },
    { name: 'Generator', unit: 'Piece', orders: [
      { quantity: 5, total_price: 10_000.00, supplier: 'PT Mesin Pertanian', days_ago: 220 },
      { quantity: 3, total_price: 6000.00, supplier: 'PT Mesin Pertanian', days_ago: 70 }
    ] },
    { name: 'Lawn Mower', unit: 'Piece', orders: [
      { quantity: 7, total_price: 12_600.00, supplier: 'CV Teknik Jaya', days_ago: 150 }
    ] }
  ]
}

# Create inventories with their initial orders
existing_inventories = Inventory.pluck(:name)

inventory_data.each do |category_name, items|
  category_id = categories[category_name]

  items.each do |item|
    next if existing_inventories.include?(item[:name])

    unit_id = units[item[:unit]]

    # Create inventory and its inventory_orders explicitly (avoid nested attributes dependency)
    inventory = Inventory.create!(
      name: item[:name],
      category_id: category_id,
      unit_id: unit_id
    )

    item[:orders].each do |order|
      purchase_date = Date.current - order[:days_ago].days
      InventoryOrder.create!(
        inventory_id: inventory.id,
        quantity: order[:quantity],
        total_price: order[:total_price],
        supplier: order[:supplier],
        purchase_date: purchase_date,
        date_of_arrival: purchase_date + rand(3..14).days
      )
    end
  end
end

puts "✓ Created #{Inventory.count} inventory items with #{InventoryOrder.count} orders"
