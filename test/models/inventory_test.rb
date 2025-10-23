# == Schema Information
#
# Table name: inventories
#
#  id             :bigint           not null, primary key
#  currency       :string           default("RM")
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
require "test_helper"

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
