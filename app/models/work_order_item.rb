class WorkOrderItem < ApplicationRecord
  belongs_to :work_order
  belongs_to :inventory, optional: true

  validates :inventory_id, presence: true
  validates :amount_used, numericality: { greater_than: 0 }, allow_nil: true

  before_save :populate_inventory_details

  private

  def populate_inventory_details
    return unless inventory_id_changed? && inventory

    self.item_name = inventory.name
    self.price = inventory.price
    self.unit_name = inventory.unit&.name
    self.category_name = inventory.category&.name
  end
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
