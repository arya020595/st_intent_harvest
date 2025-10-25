class WorkOrderItem < ApplicationRecord
  belongs_to :work_order
  belongs_to :inventory, optional: true
  
  validates :item_name, presence: true
  validates :amount_used, numericality: { greater_than: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

# == Schema Information
#
# Table name: work_order_items
#
#  id            :integer          not null, primary key
#  work_order_id :integer          not null
#  inventory_id  :integer
#  item_name     :string
#  amount_used   :integer
#  price         :decimal(10, 2)
#  unit_name     :string
#  category_name :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_work_order_items_on_inventory_id   (inventory_id)
#  index_work_order_items_on_work_order_id  (work_order_id)
#
