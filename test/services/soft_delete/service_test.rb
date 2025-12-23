# frozen_string_literal: true

require 'test_helper'

class SoftDeleteServiceTest < ActiveSupport::TestCase
  setup do
    @worker = workers(:one)
  end

  # ============================================
  # Delete Action Tests
  # ============================================

  test 'delete action soft deletes a record' do
    result = SoftDelete::Service.call(@worker, action: :delete)

    assert result.success?
    assert @worker.discarded?
  end

  test 'delete action returns Success monad with record' do
    result = SoftDelete::Service.call(@worker, action: :delete)

    assert result.success?
    assert_equal @worker, result.value!
  end

  test 'delete action fails for already deleted record' do
    @worker.discard

    result = SoftDelete::Service.call(@worker, action: :delete)

    assert result.failure?
    assert_equal :already_deleted, result.failure
  end

  test 'delete action with reason tracks the reason' do
    result = SoftDelete::Service.call(@worker, action: :delete, reason: 'Terminated')

    assert result.success?
    assert @worker.discarded?
  end

  # ============================================
  # Restore Action Tests
  # ============================================

  test 'restore action restores a discarded record' do
    @worker.discard

    result = SoftDelete::Service.call(@worker, action: :restore)

    assert result.success?
    assert @worker.kept?
  end

  test 'restore action returns Success monad with record' do
    @worker.discard

    result = SoftDelete::Service.call(@worker, action: :restore)

    assert result.success?
    assert_equal @worker, result.value!
  end

  test 'restore action fails for non-deleted record' do
    result = SoftDelete::Service.call(@worker, action: :restore)

    assert result.failure?
    assert_equal :not_deleted, result.failure
  end

  # ============================================
  # Validation Tests
  # ============================================

  test 'returns failure for invalid action' do
    result = SoftDelete::Service.call(@worker, action: :invalid)

    assert result.failure?
    assert_equal :invalid_action, result.failure
  end

  test 'returns failure for non-soft-deletable model' do
    # Create a mock object that doesn't support soft delete
    mock_record = Struct.new(:id).new(1)

    # Define class method on the struct's class
    def mock_record.class
      Class.new do
        def self.soft_deletable?
          false
        end

        def self.respond_to?(method, *)
          method == :soft_deletable? || super
        end
      end.new.class
    end

    result = SoftDelete::Service.call(mock_record, action: :delete)

    assert result.failure?
    assert_equal :not_soft_deletable, result.failure
  end

  # ============================================
  # Class Method Tests
  # ============================================

  test 'call class method instantiates and calls service' do
    result = SoftDelete::Service.call(@worker, action: :delete)

    assert result.success?
    assert @worker.discarded?
  end
end
