# frozen_string_literal: true
# == Schema Information
#
# Table name: inventories
#
#  id          :integer          not null, primary key
#  category_id :integer
#  created_at  :datetime         not null
#  name        :string           not null
#  unit_id     :integer
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_inventories_on_category_id  (category_id)
#  index_inventories_on_unit_id      (unit_id)
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  test 'total_stock correctly sums quantities from all related inventory_orders' do
    inventory = inventories(:one)
    
    # Expected total: 50 + 30 + 20 = 100
    assert_equal 100, inventory.total_stock,
                 'total_stock should sum all inventory_orders quantities'
  end

  test 'total_stock returns 0 when there are no orders' do
    inventory = inventories(:three)
    
    # Ensure no orders exist for this inventory
    assert_equal 0, inventory.inventory_orders.count,
                 'Inventory three should have no orders'
    
    assert_equal 0, inventory.total_stock,
                 'total_stock should return 0 when there are no inventory_orders'
  end

  test 'total_stock with single inventory order' do
    inventory = inventories(:two)
    
    # Expected total: 50 (single order)
    assert_equal 50, inventory.total_stock,
                 'total_stock should work correctly with a single order'
  end

  test 'inventory_orders association is properly configured' do
    inventory = inventories(:one)
    
    assert_respond_to inventory, :inventory_orders,
                      'Inventory should have inventory_orders association'
    
    assert_equal 3, inventory.inventory_orders.count,
                 'Inventory one should have 3 inventory orders'
  end

  test 'inventory_orders association has dependent destroy' do
    inventory = inventories(:one)
    inventory_id = inventory.id
    
    # Ensure we have orders before deletion
    assert inventory.inventory_orders.count > 0,
           'Inventory should have orders before deletion'
    
    # Delete the inventory
    inventory.destroy
    
    # Verify all related orders are also destroyed
    assert_equal 0, InventoryOrder.where(inventory_id: inventory_id).count,
                 'Related inventory_orders should be destroyed when inventory is destroyed'
  end

  test 'total_stock updates when new order is added' do
    inventory = inventories(:three)
    initial_stock = inventory.total_stock
    
    # Add a new order
    inventory.inventory_orders.create!(
      quantity: 25,
      unit_price: 3.00,
      total_price: 75.00,
      supplier: 'Tool Supply Co',
      purchase_date: Date.today
    )
    
    # Reload to get updated data
    inventory.reload
    
    assert_equal initial_stock + 25, inventory.total_stock,
                 'total_stock should update when new order is added'
  end

  test 'total_stock updates when order is removed' do
    inventory = inventories(:one)
    initial_stock = inventory.total_stock
    
    # Remove one order
    order_to_remove = inventory.inventory_orders.first
    removed_quantity = order_to_remove.quantity
    order_to_remove.destroy
    
    # Reload to get updated data
    inventory.reload
    
    assert_equal initial_stock - removed_quantity, inventory.total_stock,
                 'total_stock should update when order is removed'
  end
end
