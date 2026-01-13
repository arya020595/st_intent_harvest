# frozen_string_literal: true

# == Schema Information
#
# Table name: roles_permissions
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  permission_id :integer          not null
#  role_id       :integer          not null
#  updated_at    :datetime         not null
#  discarded_at  :datetime
#
# Indexes
#
#  index_roles_permissions_on_discarded_at               (discarded_at)
#  index_roles_permissions_on_permission_id              (permission_id)
#  index_roles_permissions_on_role_id                    (role_id)
#  index_roles_permissions_on_role_id_and_permission_id  (role_id,permission_id) UNIQUE
#

require 'test_helper'

class RolesPermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
