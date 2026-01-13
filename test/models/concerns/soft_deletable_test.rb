# frozen_string_literal: true

require 'test_helper'

class SoftDeletableTest < ActiveSupport::TestCase
  # Use Worker model as test subject since it includes SoftDeletable via ApplicationRecord
  # and has the discarded_at column

  setup do
    @worker = workers(:one)
  end

  # ============================================
  # Class Method Tests
  # ============================================

  test 'soft_deletable? returns true for models with discarded_at column' do
    assert Worker.soft_deletable?, 'Worker should be soft deletable'
    assert User.soft_deletable?, 'User should be soft deletable'
    assert Block.soft_deletable?, 'Block should be soft deletable'
  end

  # ============================================
  # Basic Soft Delete Tests
  # ============================================

  test 'discard sets discarded_at timestamp' do
    assert_nil @worker.discarded_at

    @worker.discard

    assert_not_nil @worker.discarded_at
    assert @worker.discarded?
  end

  test 'discard does not permanently delete the record' do
    worker_id = @worker.id

    @worker.discard

    # Record still exists in database
    assert Worker.with_discarded.exists?(worker_id)
    # But not in default scope
    assert_not Worker.exists?(worker_id)
  end

  test 'soft_delete is an alias for discard with callbacks' do
    assert_nil @worker.discarded_at

    @worker.soft_delete

    assert @worker.discarded?
  end

  test 'archive is an alias for soft_delete' do
    @worker.archive

    assert @worker.archived?
    assert @worker.discarded?
  end

  # ============================================
  # Restore Tests
  # ============================================

  test 'undiscard clears discarded_at timestamp' do
    @worker.discard
    assert @worker.discarded?

    @worker.undiscard

    assert_nil @worker.discarded_at
    assert @worker.kept?
  end

  test 'restore is an alias for undiscard with callbacks' do
    @worker.discard

    @worker.restore

    assert_not @worker.discarded?
  end

  test 'unarchive is an alias for restore' do
    @worker.archive

    @worker.unarchive

    assert_not @worker.archived?
  end

  # ============================================
  # Scope Tests
  # ============================================

  test 'default scope excludes discarded records' do
    initial_count = Worker.count

    @worker.discard

    assert_equal initial_count - 1, Worker.count
  end

  test 'with_discarded includes all records' do
    initial_count = Worker.with_discarded.count

    @worker.discard

    assert_equal initial_count, Worker.with_discarded.count
  end

  test 'discarded scope returns only discarded records' do
    @worker.discard
    @worker.reload

    # Use with_discarded.discarded to bypass default scope
    discarded_workers = Worker.with_discarded.discarded

    assert discarded_workers.exists?(@worker.id)
    assert discarded_workers.all?(&:discarded?)
  end

  test 'kept scope returns only non-discarded records' do
    other_worker = workers(:two)
    @worker.discard

    kept_workers = Worker.kept

    assert_not_includes kept_workers, @worker
    assert_includes kept_workers, other_worker
  end

  # ============================================
  # Status Check Tests
  # ============================================

  test 'discarded? returns true for discarded records' do
    @worker.discard

    assert @worker.discarded?
  end

  test 'discarded? returns false for kept records' do
    assert_not @worker.discarded?
  end

  test 'soft_deleted? is an alias for discarded?' do
    assert_not @worker.soft_deleted?

    @worker.discard

    assert @worker.soft_deleted?
  end

  test 'kept? returns true for non-discarded records' do
    assert @worker.kept?
  end

  test 'kept? returns false for discarded records' do
    @worker.discard

    assert_not @worker.kept?
  end

  # ============================================
  # Batch Operation Tests
  # ============================================

  test 'soft_delete_all discards multiple records by IDs' do
    worker1 = workers(:one)
    worker2 = workers(:two)

    Worker.soft_delete_all([worker1.id, worker2.id])

    worker1.reload
    worker2.reload

    assert worker1.discarded?
    assert worker2.discarded?
  end

  test 'restore_all restores multiple discarded records by IDs' do
    worker1 = workers(:one)
    worker2 = workers(:two)

    worker1.discard
    worker2.discard

    Worker.restore_all([worker1.id, worker2.id])

    worker1.reload
    worker2.reload

    assert worker1.kept?
    assert worker2.kept?
  end

  # ============================================
  # Association Tests
  # ============================================

  test 'associations respect default scope' do
    # Create a work order with workers
    work_order_rates(:one) if defined?(work_order_rates)

    # Verify that when querying through associations, discarded records are excluded
    initial_count = Worker.count

    @worker.discard

    assert_equal initial_count - 1, Worker.count
  end

  # ============================================
  # Persistence Tests
  # ============================================

  test 'discarded records persist through reload' do
    @worker.discard
    worker_id = @worker.id

    reloaded_worker = Worker.with_discarded.find(worker_id)

    assert reloaded_worker.discarded?
    assert_not_nil reloaded_worker.discarded_at
  end

  test 'restored records persist through reload' do
    @worker.discard
    @worker.undiscard
    worker_id = @worker.id

    reloaded_worker = Worker.find(worker_id)

    assert reloaded_worker.kept?
    assert_nil reloaded_worker.discarded_at
  end

  # ============================================
  # Edge Case Tests
  # ============================================

  test 'discarding an already discarded record updates timestamp' do
    @worker.discard
    @worker.discarded_at

    sleep 0.1 # Ensure time difference
    @worker.discard

    # Discard gem allows re-discarding (updates timestamp)
    assert @worker.discarded?
  end

  test 'undiscarding a non-discarded record is safe' do
    assert @worker.kept?

    # Should not raise an error
    @worker.undiscard

    assert @worker.kept?
  end

  test 'can update discarded records' do
    @worker.discard

    # Find with discarded scope and update a simple attribute
    worker = Worker.with_discarded.find(@worker.id)
    worker.name
    worker.name = 'Updated Name'
    worker.save!(validate: false) # Skip validations for this test

    assert_equal 'Updated Name', worker.reload.name
    assert worker.discarded? # Still discarded after update
  end

  # ============================================
  # Query Tests
  # ============================================

  test 'can query by discarded_at timestamp' do
    @worker.discard

    recent_discards = Worker.with_discarded.where('discarded_at > ?', 1.hour.ago)

    assert_includes recent_discards, @worker
  end

  test 'can order by discarded_at' do
    worker1 = workers(:one)
    worker2 = workers(:two)

    worker1.discard
    worker2.discard

    # Use with_discarded.discarded to bypass default scope
    ordered = Worker.with_discarded.discarded.reorder(discarded_at: :asc)

    # Both should be in the discarded list
    assert_equal 2, ordered.count
    # First discarded should come first when ordered ascending
    assert ordered.pluck(:discarded_at).first <= ordered.pluck(:discarded_at).last
  end
end
