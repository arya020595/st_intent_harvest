# frozen_string_literal: true

class AddUserNameToWorkOrderHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_histories, :user_name, :string
  end
end
