# frozen_string_literal: true

class Block < ApplicationRecord
  has_many :work_orders, dependent: :nullify

  validates :block_number, presence: true, uniqueness: true
  validates :hectarage, numericality: { greater_than: 0 }, allow_nil: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id block_number hectarage created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[work_orders]
  end
end

# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  block_number :string
#  hectarage    :decimal(10, 2)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
