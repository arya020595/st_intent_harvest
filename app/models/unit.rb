# frozen_string_literal: true

class Unit < ApplicationRecord
  has_many :inventories, dependent: :nullify
  has_many :work_order_rates, dependent: :nullify

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name unit_type created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inventories work_order_rates]
  end
end

# == Schema Information
#
# Table name: units
#
#  id         :integer          not null, primary key
#  name       :string
#  unit_type  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
