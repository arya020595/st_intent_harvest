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
#  id            :bigint           not null, primary key
#  category_type :string
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :integer
#
