class Permission < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :roles, through: :roles_permissions
  
  validates :subject, presence: true
  validates :action, presence: true
end

# == Schema Information
#
# Table name: permissions
#
#  id         :bigint           not null, primary key
#  action     :string
#  subject    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
