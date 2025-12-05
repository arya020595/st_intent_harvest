# frozen_string_literal: true

class Inventory < ApplicationRecord
  # Ignore removed columns for safe deployment
  self.ignored_columns += %w[currency input_date price stock_quantity supplier]

  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  has_many :work_order_items, dependent: :nullify
  has_many :inventory_orders, dependent: :destroy

  accepts_nested_attributes_for :inventory_orders, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: { message: 'Please enter the inventory name' }
  validates :category_id, presence: { message: 'Please select a category' }, if: lambda {
    category_id.present? || category_id.nil?
  }
  validates :unit_id, presence: { message: 'Please select a unit' }, if: -> { unit_id.present? || unit_id.nil? }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name category_id unit_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category unit work_order_items inventory_orders]
  end

  # Calculate total stock from all inventory orders
  def total_stock
    inventory_orders.sum(:quantity)
  end
end

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
