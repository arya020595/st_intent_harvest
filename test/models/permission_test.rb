# frozen_string_literal: true
# == Schema Information
#
# Table name: permissions
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  code       :string           not null
#  name       :string           not null
#  resource   :string           not null
#  section    :string
#
# Indexes
#
#  index_permissions_on_code      (code) UNIQUE
#  index_permissions_on_resource  (resource)
#

require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
