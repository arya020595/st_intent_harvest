# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :roles, through: :roles_permissions

  validates :code, presence: true, uniqueness: true, format: {
    with: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/,
    message: "must follow format: namespace.resource.action (e.g., 'admin.users.read') or resource.action (e.g., 'dashboard.index')"
  }
  validates :name, presence: true
  validates :resource, presence: true, format: {
    with: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\z/,
    message: "must follow format: namespace.resource (e.g., 'admin.users') or resource (e.g., 'dashboard')"
  }

  # Extract action from code (e.g., 'admin.users.read' => 'read', 'dashboard.index' => 'index')
  def action
    code.split('.').last
  end

  # Extract namespace from resource (e.g., 'admin.users' => 'admin', 'dashboard' => nil)
  def namespace
    parts = resource.split('.')
    parts.length > 1 ? parts.first : nil
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id code name resource created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[roles roles_permissions]
  end
end

# == Schema Information
#
# Table name: permissions
#
#  id         :integer          not null, primary key
#  code       :string           not null
#  name       :string           not null
#  resource   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_permissions_on_code      (code) UNIQUE
#  index_permissions_on_resource  (resource)
#
