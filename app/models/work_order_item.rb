class WorkOrderItem < ApplicationRecord
  belongs_to :work_order
  belongs_to :inventory, optional: true
  
  validates :item_name, presence: true
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

# == Schema Information
#
# Table name: work_order_items
#
#  id            :bigint           not null, primary key
#  category_name :string
#  item_name     :string
#  price         :decimal(10, 2)
#  quantity      :integer
#  unit_name     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  inventory_id  :bigint
#  work_order_id :bigint           not null
#
# Indexes
#
#  index_work_order_items_on_inventory_id   (inventory_id)
#  index_work_order_items_on_work_order_id  (work_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (inventory_id => inventories.id)
#  fk_rails_...  (work_order_id => work_orders.id)
#
