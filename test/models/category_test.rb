# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  category_type :string
#  created_at    :datetime         not null
#  name          :string
#  parent_id     :integer
#  updated_at    :datetime         not null
#  discarded_at  :datetime
#
# Indexes
#
#  index_categories_on_discarded_at  (discarded_at)
#

require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
