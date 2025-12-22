# frozen_string_literal: true

require 'test_helper'

class CascadingSoftDeleteTest < ActiveSupport::TestCase
  # Test the CascadingSoftDelete concern functionality
  # This concern provides batch cascade operations for soft deleting and restoring associated records

  # Create test models that use the concern
  class TestParent < ApplicationRecord
    self.table_name = 'blocks' # Reuse existing table with discarded_at
    include SoftDeletable
    include CascadingSoftDelete

    has_many :test_children, foreign_key: 'block_id', class_name: 'CascadingSoftDeleteTest::TestChild',
                             dependent: :destroy

    cascade_soft_delete :test_children
  end

  class TestChild < ApplicationRecord
    self.table_name = 'work_orders' # Reuse existing table with discarded_at
    include SoftDeletable

    belongs_to :test_parent, foreign_key: 'block_id', class_name: 'CascadingSoftDeleteTest::TestParent',
                             optional: true
  end

  setup do
    @parent = TestParent.create!(block_number: 'TEST-CASCADE-001', hectarage: 10.5)
    @child1 = TestChild.create!(
      test_parent: @parent,
      work_order_status: 'draft',
      start_date: Date.today,
      completion_date: Date.today + 7.days
    )
    @child2 = TestChild.create!(
      test_parent: @parent,
      work_order_status: 'draft',
      start_date: Date.today,
      completion_date: Date.today + 7.days
    )

    # Read the concern file content once for all tests
    @concern_file_content = File.read(Rails.root.join('app/models/concerns/cascading_soft_delete.rb'))
  end

  teardown do
    # Clean up in correct order: children first, then parent
    TestChild.with_discarded.where(block_id: @parent&.id).delete_all if @parent
    TestParent.with_discarded.where(id: @parent&.id).delete_all if @parent
  end

  # ============================================
  # Configuration Tests
  # ============================================

  test 'cascade_soft_delete configures cascade associations' do
    assert_respond_to TestParent, :_cascade_associations
    assert_equal [:test_children], TestParent._cascade_associations
  end

  # ============================================
  # Cascade Discard Tests
  # ============================================

  test 'discarding parent cascades to children using batch update' do
    @parent.discard

    assert @parent.discarded?
    assert @child1.reload.discarded?
    assert @child2.reload.discarded?
  end

  test 'cascade discard only affects kept children' do
    # Discard one child manually first
    @child1.discard
    first_discarded_at = @child1.discarded_at

    # Discard parent (should cascade to child2 only)
    @parent.discard

    assert @parent.discarded?
    assert @child1.reload.discarded?
    assert @child2.reload.discarded?

    # child1's discarded_at should not have changed (was already discarded)
    assert_equal first_discarded_at.to_i, @child1.reload.discarded_at.to_i
  end

  # ============================================
  # Cascade Undiscard Tests
  # ============================================

  test 'undiscarding parent cascades to children using batch update' do
    @parent.discard
    assert @child1.reload.discarded?
    assert @child2.reload.discarded?

    @parent.undiscard

    assert @parent.kept?
    assert @child1.reload.kept?
    assert @child2.reload.kept?
  end

  test 'cascade undiscard only affects discarded children' do
    @child1.discard
    @child2.discard

    # Restore child1 manually
    @child1.undiscard

    # Now discard and restore parent
    @parent.discard
    @parent.undiscard

    # Both children should be restored (child1 was already restored, child2 was discarded)
    assert @child1.reload.kept?
    assert @child2.reload.kept?
  end

  # ============================================
  # Batch Update Performance Tests
  # ============================================
  # Note: These tests verify implementation details (source code) rather than behavior
  # because the performance optimization is critical and we want to ensure it's maintained.
  # Testing the actual SQL queries would require a database connection and fixtures,
  # which adds complexity for this concern that may not be used yet.

  test 'cascade_undiscard_association uses batch update instead of individual calls' do
    # This test verifies that the implementation uses update_all for performance
    # The implementation should use query.update_all(discarded_at: nil) instead of
    # iterating through records with find_each and calling undiscard on each one

    # Verify the implementation by checking the code uses update_all
    assert_match(/update_all\(discarded_at: nil\)/, @concern_file_content,
                 'cascade_undiscard_association should use update_all for batch updates')
  end

  test 'cascade_discard_association uses batch update instead of individual calls' do
    # Verify the implementation uses update_all for discarding as well
    assert_match(/update_all\(discarded_at: Time\.current\)/, @concern_file_content,
                 'cascade_discard_association should use update_all for batch updates')
  end

  # ============================================
  # Association Type Support Tests
  # ============================================

  test 'implementation supports polymorphic associations' do
    # Verify polymorphic association handling exists
    assert_match(/polymorphic\?/, @concern_file_content,
                 'Should check for polymorphic associations')
    assert_match(/foreign_type/, @concern_file_content,
                 'Should handle foreign_type for polymorphic associations')
  end

  test 'implementation supports custom foreign keys' do
    # The implementation should use association.foreign_key to get the correct foreign key
    assert_match(/association\.foreign_key/, @concern_file_content,
                 'Should use association.foreign_key for custom foreign keys')
  end

  test 'implementation handles has_many through associations' do
    # Verify that has_many :through is handled appropriately
    assert_match(/through_reflection/, @concern_file_content,
                 'Should check for has_many :through associations')
  end

  # ============================================
  # Documentation Tests
  # ============================================
  #
  # NOTE: Previous tests in this section asserted specific documentation
  # strings by reading the concern source file. Those tests were removed
  # because testing documentation via implementation string matching is
  # fragile and not a best practice.
end
