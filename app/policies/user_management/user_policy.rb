# frozen_string_literal: true

module UserManagement
  class UserPolicy < ApplicationPolicy

  def destroy?
      # Adjust this to your actual permission logic
      true
    end

    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

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
