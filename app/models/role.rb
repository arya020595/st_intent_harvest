class Role < ApplicationRecord
  has_many :users
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions
  
  validates :name, presence: true, uniqueness: true
end
