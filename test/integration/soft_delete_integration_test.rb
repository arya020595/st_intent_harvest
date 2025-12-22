# frozen_string_literal: true

require 'test_helper'

class SoftDeleteIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:superadmin)
    sign_in @user

    @worker = workers(:one)
  end

  # ============================================
  # Complete Workflow Tests
  # ============================================

  test 'complete soft delete and restore workflow' do
    worker_id = @worker.id

    # Step 1: Verify worker exists and is visible
    get workers_path
    assert_response :success
    initial_count = Worker.count

    # Step 2: Soft delete the worker
    delete worker_path(@worker)
    assert_redirected_to workers_path

    # Step 3: Verify worker is excluded from default scope
    assert_equal initial_count - 1, Worker.count

    # Step 4: Verify worker still exists in database
    assert Worker.with_discarded.exists?(worker_id)
    discarded_worker = Worker.with_discarded.find(worker_id)
    assert discarded_worker.discarded?
    assert_not_nil discarded_worker.discarded_at

    # Step 5: Restore the worker
    patch restore_worker_path(id: worker_id)
    assert_redirected_to workers_path

    # Step 6: Verify worker is back in default scope
    assert_equal initial_count, Worker.count

    # Step 7: Verify worker is no longer discarded
    restored_worker = Worker.find(worker_id)
    assert restored_worker.kept?
    assert_nil restored_worker.discarded_at
  end

  # ============================================
  # Master Data Soft Delete Tests
  # ============================================

  test 'soft delete block through master data controller' do
    block = blocks(:one) if defined?(blocks)
    skip 'No blocks fixture' unless block

    block_id = block.id

    delete master_data_block_path(block)

    assert_redirected_to master_data_blocks_path
    assert Block.with_discarded.find(block_id).discarded?
  end

  test 'restore block through master data controller' do
    block = blocks(:one) if defined?(blocks)
    skip 'No blocks fixture' unless block

    block.discard

    patch restore_master_data_block_path(block)

    assert_redirected_to master_data_blocks_path
    assert block.reload.kept?
  end

  # ============================================
  # User Management Soft Delete Tests
  # ============================================

  test 'soft delete user through user management controller' do
    # Create a user to delete (don't delete the superadmin we're logged in as)
    user_to_delete = users(:clerk) if defined?(users)
    skip 'No clerk user fixture' unless user_to_delete

    user_id = user_to_delete.id

    delete user_management_user_path(user_to_delete)

    assert User.with_discarded.find(user_id).discarded?
  end

  # ============================================
  # Work Orders Soft Delete Tests
  # ============================================

  test 'soft delete work order through work orders controller' do
    work_order = work_orders(:one) if defined?(work_orders)
    skip 'No work_orders fixture' unless work_order

    work_order_id = work_order.id

    delete work_orders_detail_path(work_order)

    assert_redirected_to work_orders_details_path
    assert WorkOrder.with_discarded.find(work_order_id).discarded?
  end

  # ============================================
  # Multiple Model Tests
  # ============================================

  test 'soft delete works consistently across different models' do
    models_to_test = [
      { model: Worker, record: @worker, path_helper: :worker_path }
    ]

    models_to_test.each do |test_case|
      record = test_case[:record]
      path = send(test_case[:path_helper], record)

      # Soft delete
      delete path

      # Verify discarded
      assert record.reload.discarded?, "#{test_case[:model]} should be discarded"

      # Restore
      restore_path = send("restore_#{test_case[:path_helper]}", record)
      patch restore_path

      # Verify restored
      assert record.reload.kept?, "#{test_case[:model]} should be restored"
    end
  end

  # ============================================
  # Data Integrity Tests
  # ============================================

  test 'soft deleted records maintain all data' do
    original_name = @worker.name
    original_identity = @worker.identity_number

    @worker.discard
    @worker.reload

    discarded = Worker.with_discarded.find(@worker.id)

    assert_equal original_name, discarded.name
    assert_equal original_identity, discarded.identity_number
  end

  test 'restored records have original data intact' do
    original_name = @worker.name

    @worker.discard
    @worker.undiscard
    @worker.reload

    assert_equal original_name, @worker.name
  end

  # ============================================
  # Concurrent Access Tests
  # ============================================

  test 'multiple soft deletes do not cause errors' do
    worker1 = workers(:one)
    worker2 = workers(:two)

    # Soft delete multiple workers
    delete worker_path(worker1)
    delete worker_path(worker2)

    assert worker1.reload.discarded?
    assert worker2.reload.discarded?
  end

  # ============================================
  # API Response Tests
  # ============================================

  test 'JSON API returns proper response for soft delete' do
    delete worker_path(@worker), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_not_nil json['id']
    assert_equal @worker.id, json['id']
  end

  test 'JSON API returns proper response for restore' do
    @worker.discard

    patch restore_worker_path(@worker), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_nil json['discarded_at']
  end
end
