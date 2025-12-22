# frozen_string_literal: true

require 'test_helper'

class SoftDeleteBatchServiceTest < ActiveSupport::TestCase
  setup do
    @worker1 = workers(:one)
    @worker2 = workers(:two)
  end

  # ============================================
  # Batch Delete Tests
  # ============================================

  test 'batch delete soft deletes multiple records' do
    ids = [@worker1.id, @worker2.id]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :delete)

    assert result.success?

    @worker1.reload
    @worker2.reload

    assert @worker1.discarded?
    assert @worker2.discarded?
  end

  test 'batch delete returns success with count' do
    ids = [@worker1.id, @worker2.id]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :delete)

    assert result.success?
    assert_includes result.value!.keys, :deleted_count
  end

  # ============================================
  # Batch Restore Tests
  # ============================================

  test 'batch restore restores multiple discarded records' do
    @worker1.discard
    @worker2.discard
    ids = [@worker1.id, @worker2.id]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :restore)

    assert result.success?

    @worker1.reload
    @worker2.reload

    assert @worker1.kept?
    assert @worker2.kept?
  end

  test 'batch restore returns success with count' do
    @worker1.discard
    @worker2.discard
    ids = [@worker1.id, @worker2.id]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :restore)

    assert result.success?
    assert_includes result.value!.keys, :restored_count
  end

  # ============================================
  # Validation Tests
  # ============================================

  test 'returns failure for empty ids array' do
    result = SoftDelete::BatchService.call(Worker, ids: [], action: :delete)

    assert result.failure?
    assert_equal :empty_ids, result.failure
  end

  test 'returns failure for invalid action' do
    result = SoftDelete::BatchService.call(Worker, ids: [@worker1.id], action: :invalid)

    assert result.failure?
    assert_equal :invalid_action, result.failure
  end

  test 'handles single id as array' do
    result = SoftDelete::BatchService.call(Worker, ids: @worker1.id, action: :delete)

    assert result.success?
    assert @worker1.reload.discarded?
  end

  # ============================================
  # Edge Cases
  # ============================================

  test 'batch delete skips non-existent ids gracefully' do
    ids = [@worker1.id, 999_999]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :delete)

    assert result.success?
    assert @worker1.reload.discarded?
  end

  test 'batch restore only affects discarded records' do
    @worker1.discard
    # worker2 is not discarded
    ids = [@worker1.id, @worker2.id]

    result = SoftDelete::BatchService.call(Worker, ids: ids, action: :restore)

    assert result.success?
    assert @worker1.reload.kept?
    assert @worker2.reload.kept? # Was already kept
  end
end
