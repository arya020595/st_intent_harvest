# frozen_string_literal: true

class Mill < ApplicationRecord
  include Discard::Model

  has_many :productions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[productions]
  end

  def display_name
    name
  end
end

# == Schema Information
#
# Table name: mills
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  discarded_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_mills_on_discarded_at  (discarded_at)
#  index_mills_on_name          (name) UNIQUE
#
