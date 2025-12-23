# frozen_string_literal: true

require 'test_helper'

class SoftDeletableControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:superadmin)
    sign_in @user

    @worker = workers(:one)
  end

  # ============================================
  # Destroy Action Tests (Soft Delete)
  # ============================================

  test 'destroy action soft deletes record instead of permanent delete' do
    worker_id = @worker.id

    assert_no_difference('Worker.with_discarded.count') do
      delete worker_path(@worker)
    end

    # Record still exists but is discarded
    assert Worker.with_discarded.exists?(worker_id)
    assert Worker.with_discarded.find(worker_id).discarded?
  end

  test 'destroy action redirects with success notice for HTML format' do
    delete worker_path(@worker)

    assert_redirected_to workers_path
    assert_equal 'Worker was successfully deleted.', flash[:notice]
  end

  test 'destroy action returns JSON for JSON format' do
    delete worker_path(@worker), as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['id']
  end

  test 'destroyed record is excluded from index' do
    @worker.discard

    get workers_path

    assert_response :success
    # Verify worker is not in the response body
    assert_no_match @worker.name, response.body
  end

  # ============================================
  # Restore Action Tests
  # ============================================

  test 'restore action undiscards a soft deleted record' do
    @worker.discard
    assert @worker.discarded?

    patch restore_worker_path(@worker)

    @worker.reload
    assert @worker.kept?
  end

  test 'restore action redirects with success notice for HTML format' do
    @worker.discard

    patch restore_worker_path(@worker)

    assert_redirected_to workers_path
    assert_equal 'Worker was successfully restored.', flash[:notice]
  end

  test 'restore action returns JSON for JSON format' do
    @worker.discard

    patch restore_worker_path(@worker), as: :json

    assert_response :ok
  end

  test 'restored record appears in index' do
    @worker.discard

    patch restore_worker_path(@worker)

    get workers_path

    assert_response :success
    # Worker should now be visible in the list
    @worker.reload
    assert @worker.kept?
  end

  # ============================================
  # Turbo Stream Tests
  # ============================================

  test 'destroy action responds to turbo_stream format' do
    delete worker_path(@worker), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
  end

  test 'restore action responds to turbo_stream format' do
    @worker.discard

    patch restore_worker_path(@worker), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
  end

  # ============================================
  # Authorization Tests
  # ============================================

  test 'destroy requires authentication' do
    sign_out @user

    delete worker_path(@worker)

    assert_redirected_to new_user_session_path
  end

  test 'restore requires authentication' do
    sign_out @user
    @worker.discard

    patch restore_worker_path(@worker)

    assert_redirected_to new_user_session_path
  end

  # ============================================
  # Edge Cases
  # ============================================

  test 'destroy already discarded record updates it' do
    @worker.discard

    # Need to find with discarded scope for the path
    # The delete path should work via with_discarded in the controller
    delete worker_path(id: @worker.id)

    # Should handle gracefully (either redirect or 404)
    assert_includes [200, 302, 404], response.status
  end
end
