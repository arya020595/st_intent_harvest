# frozen_string_literal: true

require 'test_helper'

class UserRedirectServiceTest < ActiveSupport::TestCase
  setup do
    # Create roles with specific permissions
    @superadmin_role = roles(:superadmin)
    @manager_role = roles(:manager)
    @field_conductor_role = roles(:field_conductor)
    @clerk_role = roles(:clerk)

    # Create users with different roles
    @superadmin = users(:superadmin)
    @manager = users(:manager)
    @field_conductor = users(:field_conductor)
    @clerk = users(:clerk)
  end

  test 'superadmin redirects to root_path' do
    service = UserRedirectService.new(@superadmin)
    assert_equal :root_path, service.first_accessible_path
  end

  test 'manager with dashboard access redirects to root_path' do
    service = UserRedirectService.new(@manager)
    assert_equal :root_path, service.first_accessible_path
  end

  test 'field conductor redirects to work_orders_details_path' do
    service = UserRedirectService.new(@field_conductor)
    assert_equal :work_orders_details_path, service.first_accessible_path
  end

  test 'clerk redirects to work_orders_pay_calculations_path' do
    service = UserRedirectService.new(@clerk)
    assert_equal :work_orders_pay_calculations_path, service.first_accessible_path
  end

  test 'class method first_accessible_path_for works' do
    path = UserRedirectService.first_accessible_path_for(@manager)
    assert_equal :root_path, path
  end

  test 'user without any permissions falls back to root_path' do
    user = User.new(name: 'No Permissions User', email: 'noperm@example.com')
    user.role = Role.new(name: 'Empty Role')

    service = UserRedirectService.new(user)
    assert_equal :root_path, service.first_accessible_path
  end
end
