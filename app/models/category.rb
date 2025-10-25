class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id', dependent: :nullify
  has_many :inventories, dependent: :nullify
  
  validates :name, presence: true
end

# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  name          :string
#  category_type :string
#  parent_id     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
