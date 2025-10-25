class RolesPermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission
end

# == Schema Information
#
# Table name: roles_permissions
#
#  id            :integer          not null, primary key
#  role_id       :integer          not null
#  permission_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_roles_permissions_on_permission_id              (permission_id)
#  index_roles_permissions_on_role_id                    (role_id)
#  index_roles_permissions_on_role_id_and_permission_id  (role_id,permission_id) UNIQUE
#
