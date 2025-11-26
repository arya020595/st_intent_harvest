# frozen_string_literal: true

module UserManagement
  class RolePolicy < ApplicationPolicy
    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end
    private

    def permission_resource
      'admin.roles'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'admin.roles'
      end
    end
  end
end
