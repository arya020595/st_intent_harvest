# frozen_string_literal: true

require 'test_helper'

class UserSoftDeleteTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test 'active user can authenticate' do
    assert @user.active_for_authentication?
  end

  test 'discarded user cannot authenticate' do
    @user.discard

    assert_not @user.active_for_authentication?
  end

  test 'restored user can authenticate again' do
    @user.discard
    assert_not @user.active_for_authentication?

    @user.undiscard
    assert @user.active_for_authentication?
    assert_not_equal :discarded, @user.inactive_message
  end

  test 'inactive_message returns :discarded for discarded users' do
    @user.discard

    assert_equal :discarded, @user.inactive_message
  end

  test 'inactive_message returns default for active users' do
    # Default Devise behavior for active users
    assert_not_equal :discarded, @user.inactive_message
  end
end
