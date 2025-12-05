# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_orders
#
#  id            :integer          not null, primary key
#  inventory_id  :integer          not null
#  quantity      :integer          not null
#  unit_price    :decimal(10, 2)
#  total_price   :decimal(10, 2)   not null
#  supplier      :string           not null
#  purchase_date :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_inventory_orders_on_inventory_id   (inventory_id)
#  index_inventory_orders_on_purchase_date  (purchase_date)
#

require "test_helper"

class InventoryOrderTest < ActiveSupport::TestCase
  def setup
    @inventory = inventories(:one)
    @valid_attributes = {
      inventory: @inventory,
      quantity: 10,
      total_price: 100.00,
      supplier: "Test Supplier",
      purchase_date: Date.today
    }
  end

  # Tests for calculate_unit_price callback
  test "should calculate unit_price correctly from total_price and quantity" do
    order = InventoryOrder.new(@valid_attributes)
    order.save!
    
    assert_equal 10.00, order.unit_price
  end

  test "should round unit_price to 2 decimal places" do
    order = InventoryOrder.new(@valid_attributes.merge(quantity: 3, total_price: 10.00))
    order.save!
    
    assert_equal 3.33, order.unit_price
  end

  test "should recalculate unit_price when quantity changes" do
    order = InventoryOrder.create!(@valid_attributes)
    order.quantity = 5
    order.save!
    
    assert_equal 20.00, order.unit_price
  end

  test "should recalculate unit_price when total_price changes" do
    order = InventoryOrder.create!(@valid_attributes)
    order.total_price = 200.00
    order.save!
    
    assert_equal 20.00, order.unit_price
  end

  test "should not calculate unit_price when quantity is zero" do
    order = InventoryOrder.new(@valid_attributes.merge(quantity: 0))
    
    # Validation should fail before calculate_unit_price runs
    assert_not order.valid?
  end

  test "should not calculate unit_price when quantity is nil" do
    order = InventoryOrder.new(@valid_attributes.except(:quantity))
    
    assert_not order.valid?
    assert_includes order.errors[:quantity], "can't be blank"
  end

  test "should not calculate unit_price when total_price is nil" do
    order = InventoryOrder.new(@valid_attributes.except(:total_price))
    
    assert_not order.valid?
    assert_includes order.errors[:total_price], "can't be blank"
  end

  # Tests for quantity validation
  test "should be valid with valid attributes" do
    order = InventoryOrder.new(@valid_attributes)
    assert order.valid?
  end

  test "should require quantity" do
    order = InventoryOrder.new(@valid_attributes.except(:quantity))
    assert_not order.valid?
    assert_includes order.errors[:quantity], "can't be blank"
  end

  test "should reject negative quantity" do
    order = InventoryOrder.new(@valid_attributes.merge(quantity: -1))
    assert_not order.valid?
    assert_includes order.errors[:quantity], "must be greater than 0"
  end

  test "should reject zero quantity" do
    order = InventoryOrder.new(@valid_attributes.merge(quantity: 0))
    assert_not order.valid?
    assert_includes order.errors[:quantity], "must be greater than 0"
  end

  test "should reject non-integer quantity" do
    order = InventoryOrder.new(@valid_attributes.merge(quantity: 1.5))
    assert_not order.valid?
    assert_includes order.errors[:quantity], "must be an integer"
  end

  # Tests for total_price validation
  test "should require total_price" do
    order = InventoryOrder.new(@valid_attributes.except(:total_price))
    assert_not order.valid?
    assert_includes order.errors[:total_price], "can't be blank"
  end

  test "should reject negative total_price" do
    order = InventoryOrder.new(@valid_attributes.merge(total_price: -10.00))
    assert_not order.valid?
    assert_includes order.errors[:total_price], "must be greater than 0"
  end

  test "should reject zero total_price" do
    order = InventoryOrder.new(@valid_attributes.merge(total_price: 0))
    assert_not order.valid?
    assert_includes order.errors[:total_price], "must be greater than 0"
  end

  test "should accept decimal total_price" do
    order = InventoryOrder.new(@valid_attributes.merge(total_price: 99.99))
    assert order.valid?
  end

  # Tests for supplier validation
  test "should require supplier" do
    order = InventoryOrder.new(@valid_attributes.except(:supplier))
    assert_not order.valid?
    assert_includes order.errors[:supplier], "can't be blank"
  end

  # Tests for purchase_date validation
  test "should require purchase_date" do
    order = InventoryOrder.new(@valid_attributes.except(:purchase_date))
    assert_not order.valid?
    assert_includes order.errors[:purchase_date], "can't be blank"
  end

  # Tests for associations
  test "should belong to inventory" do
    order = InventoryOrder.new(@valid_attributes.except(:inventory))
    assert_not order.valid?
  end
end
