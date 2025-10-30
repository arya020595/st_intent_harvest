class Permission < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :roles, through: :roles_permissions

  validates :subject, presence: true, format: {
    with: /\A[A-Z][a-zA-Z]*(::[A-Z][a-zA-Z]*)*\z/,
    message: "must be a valid Ruby class name (e.g., 'User' or 'WorkOrder::Detail')"
  }
  validates :action, presence: true
  validates :subject, uniqueness: { scope: :action, message: 'and action combination already exists' }
end

# == Schema Information
#
# Table name: permissions
#
#  id         :integer          not null, primary key
#  subject    :string
#  action     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
