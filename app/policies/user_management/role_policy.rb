# frozen_string_literal: true

module UserManagement
  class RolePolicy < ApplicationPolicy
    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

    def new?
      create?
    end

    def edit?
      update?
    end

    private

    def permission_resource
      'user_management.roles'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'user_management.roles'
      end
    end
  end
end
