# frozen_string_literal: true

class InventoryOrder < ApplicationRecord
  belongs_to :inventory

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :supplier, presence: true
  validates :purchase_date, presence: true

  before_save :calculate_unit_price

  def self.ransackable_attributes(_auth_object = nil)
    %w[id inventory_id quantity unit_price total_price supplier purchase_date date_of_arrival created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inventory]
  end

  private

  def calculate_unit_price
    return unless quantity.present? && quantity.positive? && total_price.present?

    self.unit_price = (total_price / quantity).round(2)
  end
end

# == Schema Information
#
# Table name: inventory_orders
#
#  id              :integer          not null, primary key
#  inventory_id    :integer          not null
#  quantity        :integer          not null
#  unit_price      :decimal(10, 2)
#  total_price     :decimal(10, 2)   not null
#  supplier        :string           not null
#  purchase_date   :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  date_of_arrival :date
#  discarded_at    :datetime
#
# Indexes
#
#  index_inventory_orders_on_discarded_at   (discarded_at)
#  index_inventory_orders_on_inventory_id   (inventory_id)
#  index_inventory_orders_on_purchase_date  (purchase_date)
#
