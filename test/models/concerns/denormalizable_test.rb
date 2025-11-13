# frozen_string_literal: true

require "test_helper"

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
    
    # Test denormalization with default behavior
    denormalize :parent_name, from: :test_parent, attribute: :name
    
    # Test denormalization with force_refresh
    denormalize :parent_number, from: :test_parent, attribute: :block_number, force_refresh: true
  end

  setup do
    @parent = TestParent.create!(block_number: 'BLOCK-001', hectarage: 10.5)
  end

  teardown do
    TestChild.delete_all
    TestParent.delete_all
  end

  test "denormalized fields populate when association is set" do
    child = TestChild.new(test_parent: @parent, start_date: Date.today)
    child.save!
    
    assert_equal 'BLOCK-001', child.parent_name
    assert_equal 'BLOCK-001', child.parent_number
  end

  test "denormalized fields update when foreign key changes" do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)
    
    new_parent = TestParent.create!(block_number: 'BLOCK-002', hectarage: 15.0)
    child.test_parent = new_parent
    child.save!
    
    assert_equal 'BLOCK-002', child.parent_name
    assert_equal 'BLOCK-002', child.parent_number
  end

  test "denormalized fields with force_refresh update on every save" do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)
    
    # Update parent name
    @parent.update!(block_number: 'BLOCK-UPDATED')
    
    # Save child without changing association
    child.save!
    
    # parent_name should NOT update (default behavior)
    assert_equal 'BLOCK-001', child.parent_name
    
    # parent_number should update (force_refresh: true)
    assert_equal 'BLOCK-UPDATED', child.parent_number
  end

  test "refresh_denormalized_fields! updates all denormalized fields" do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)
    
    # Update parent name
    @parent.update!(block_number: 'BLOCK-REFRESHED')
    
    # Manually refresh denormalized fields
    child.refresh_denormalized_fields!
    child.save!
    
    # Both fields should update
    assert_equal 'BLOCK-REFRESHED', child.parent_name
    assert_equal 'BLOCK-REFRESHED', child.parent_number
  end

  test "refresh_denormalized_fields! works without saving" do
    child = TestChild.create!(test_parent: @parent, start_date: Date.today)
    
    # Update parent name
    @parent.update!(block_number: 'BLOCK-TEMP')
    
    # Manually refresh without saving
    child.refresh_denormalized_fields!
    
    # Fields should be updated in memory
    assert_equal 'BLOCK-TEMP', child.parent_name
    assert_equal 'BLOCK-TEMP', child.parent_number
    
    # But not persisted yet
    child.reload
    assert_equal 'BLOCK-001', child.parent_name
  end
end
