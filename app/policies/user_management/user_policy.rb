# frozen_string_literal: true

module UserManagement
  class UserPolicy < ApplicationPolicy
    private

    def permission_resource
      'admin.users'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'admin.users'
      end
    end
  end
end
