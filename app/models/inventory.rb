class Inventory < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  has_many :work_order_items, dependent: :nullify
  
  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

# == Schema Information
#
# Table name: inventories
#
#  id          :bigint           not null, primary key
#  currency    :string           default("RM")
#  description :text
#  input_date  :date
#  name        :string           not null
#  price       :decimal(10, 2)
#  quantity    :integer          default(0)
#  supplier    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint
#  unit_id     :bigint
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
