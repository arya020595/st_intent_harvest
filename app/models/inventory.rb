class Inventory < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  has_many :work_order_items, dependent: :nullify

  validates :name, presence: { message: 'Please enter the inventory name' }
  validates :category_id, presence: { message: 'Please select a category' }, if: lambda {
    category_id.present? || category_id.nil?
  }
  validates :unit_id, presence: { message: 'Please select a unit' }, if: -> { unit_id.present? || unit_id.nil? }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0, message: 'Quantity must be 0 or more' },
                             allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0, message: 'Price must be 0 or more' }, allow_nil: true
  validates :supplier, presence: { message: 'Please enter supplier name' }, if: lambda {
    supplier.present? || supplier.nil?
  }
  validates :input_date, presence: { message: 'Please select an input date' }, if: lambda {
    input_date.present? || input_date.nil?
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name category_id unit_id price currency stock_quantity supplier input_date created_at updated_at]
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
