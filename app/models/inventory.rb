class Inventory < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  has_many :work_order_items, dependent: :nullify

  validates :name, presence: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name stock_quantity price currency supplier input_date created_at updated_at category_id unit_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category unit work_order_items]
  end
end

# == Schema Information
#
# Table name: inventories
#
#  id             :bigint           not null, primary key
#  currency       :string           default("RM")
#  input_date     :date
#  name           :string           not null
#  price          :decimal(10, 2)
#  stock_quantity :integer          default(0)
#  supplier       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category_id    :bigint
#  unit_id        :bigint
#
# Indexes
#
#  index_inventories_on_category_id  (category_id)
#  index_inventories_on_unit_id      (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (unit_id => units.id)
#
