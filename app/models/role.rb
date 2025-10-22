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
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
