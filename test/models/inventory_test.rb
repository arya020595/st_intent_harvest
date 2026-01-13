# frozen_string_literal: true

# == Schema Information
#
# Table name: inventories
#
#  id           :integer          not null, primary key
#  category_id  :integer
#  created_at   :datetime         not null
#  name         :string           not null
#  unit_id      :integer
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_inventories_on_category_id   (category_id)
#  index_inventories_on_discarded_at  (discarded_at)
#  index_inventories_on_unit_id       (unit_id)
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
