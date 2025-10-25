# == Schema Information
#
# Table name: pay_calculations
#
#  id            :integer          not null, primary key
#  month_year    :string           not null
#  overall_total :decimal(10, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "test_helper"

class PayCalculationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
