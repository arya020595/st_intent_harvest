class Role < ApplicationRecord
  has_many :users
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions
  
  validates :name, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
