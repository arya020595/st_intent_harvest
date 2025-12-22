# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id', dependent: :nullify
  has_many :inventories, dependent: :nullify

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name category_type parent_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[parent children inventories]
  end
end

# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  category_type :string
#  created_at    :datetime         not null
#  name          :string
#  parent_id     :integer
#  updated_at    :datetime         not null
#  discarded_at  :datetime
#
# Indexes
#
#  index_categories_on_discarded_at  (discarded_at)
#
