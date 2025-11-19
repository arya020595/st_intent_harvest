# frozen_string_literal: true

require 'test_helper'

class DenormalizableTest < ActiveSupport::TestCase
  # Create a test model that includes the Denormalizable concern
  class TestParent < ApplicationRecord
    self.table_name = 'blocks' # Reuse existing table

    def name
      block_number
    end
  end

  class TestChild < ApplicationRecord
    self.table_name = 'work_orders' # Reuse existing table
    include Denormalizable

    belongs_to :test_parent, foreign_key: 'block_id', class_name: 'DenormalizableTest::TestParent', optional: true

    # Clear inherited denormalized_fields to start fresh
    @denormalized_fields = {}

    # Test denormalization using existing columns in work_orders table
    # block_number exists in work_orders table - use it for denormalized data (no force_refresh)
    denormalize :block_number, from: :test_parent, attribute: :block_number, force_refresh: false

    # Test denormalization with force_refresh using block_hectarage (also exists)
    denormalize :block_hectarage, from: :test_parent, attribute: :hectarage, transform: lambda { |val| val.to_s },
                                  force_refresh: true
  end

  setup do
    @parent = TestParent.create!(block_number: 'BLOCK-001', hectarage: 10.5)
  end

  teardown do
    TestChild.delete_all
    TestParent.delete_all
  end

  test 'denormalized fields populate when association is set' do
    child = TestChild.new(test_parent: @parent, start_date: Date.today)
    child.save!

    assert_equal 'BLOCK-001', child.block_number
    assert_equal '10.5', child.block_hectarage
  end

  test 'denormalized fields update when foreign key changes' do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)

    new_parent = TestParent.create!(block_number: 'BLOCK-002', hectarage: 15.0)
    child.test_parent = new_parent
    child.save!

    assert_equal 'BLOCK-002', child.block_number
    assert_equal '15.0', child.block_hectarage
  end

  test 'denormalized fields with force_refresh update on every save' do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)

    # Update parent data
    @parent.update!(block_number: 'BLOCK-UPDATED', hectarage: 20.0)

    # Just changing an unrelated field and saving child
    child.work_order_status = 'completed'
    child.save!

    # With force_refresh: true, block_hectarage should update even though block_id didn't change
    assert_equal '20.0', child.block_hectarage, 'force_refresh field should update'
  end

  test 'refresh_denormalized_fields! updates all denormalized fields' do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)

    # Update parent data
    @parent.update!(block_number: 'BLOCK-REFRESHED', hectarage: 25.0)

    # Manually refresh denormalized fields
    child.refresh_denormalized_fields!
    child.save!

    # Both fields should update
    assert_equal 'BLOCK-REFRESHED', child.block_number
    assert_equal '25.0', child.block_hectarage
  end

  test 'refresh_denormalized_fields! works without saving' do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)

    # Update parent data
    @parent.update!(block_number: 'BLOCK-TEMP', hectarage: 30.0)

    # Manually refresh without saving
    child.refresh_denormalized_fields!

    # Fields should be updated in memory
    assert_equal 'BLOCK-TEMP', child.block_number
    assert_equal '30.0', child.block_hectarage

    # But not persisted yet
    child.reload
    assert_equal 'BLOCK-001', child.block_number
    assert_equal '10.5', child.block_hectarage
  end
end
