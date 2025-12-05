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
  # test "the truth" do
  #   assert true
  # end
end
