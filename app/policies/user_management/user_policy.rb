# frozen_string_literal: true

module UserManagement
  class UserPolicy < ApplicationPolicy
    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

    private

    def permission_resource
      'user_management.users'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'user_management.users'
      end
    end
  end
end
