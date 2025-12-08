# frozen_string_literal: true

module WorkOrders
  class DetailPolicy < ApplicationPolicy
    # Permission codes:
    # - work_orders.details.index
    # - work_orders.details.show
    # - work_orders.details.new
    # - work_orders.details.create
    # - work_orders.details.edit
    # - work_orders.details.update
    # - work_orders.details.destroy
    # - work_orders.details.mark_complete

    # Custom action for marking work order as complete (ongoing -> pending)
    def mark_complete?
      user.has_permission?(build_permission_code('mark_complete')) && editable?
    end

    def new?
      create?
    end

    def edit?
      update?
    end

    def update?
      user.has_permission?(build_permission_code('update')) && editable?
    end

    def destroy?
      user.has_permission?(build_permission_code('destroy')) && !destroyable?
    end

    def confirm_delete?
      destroy?
    end

    private

    def permission_resource
      'work_orders.details'
    end

    def editable?
      record.work_order_status.in?(%w[ongoing amendment_required])
    end

    def destroyable?
      record.work_order_status.in?(%w[pending completed])
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'work_orders.details'
      end

      # Override to implement role-based filtering
      def apply_role_based_scope
        # Field conductors only see their own work orders
        # Determine if user is field conductor by checking if they only have work_orders.details permissions
        if field_conductor?
          scope.where(field_conductor_id: user.id)
        else
          # Other roles (manager, clerk, etc.) with permission see all work orders
          scope.all
        end
      end

      def field_conductor?
        return false unless user.role&.permissions&.any?

        # Get all permission codes for the user's role
        permission_codes = user.role.permissions.pluck(:code)

        # Field conductor only has work_orders.details permissions
        # If there's any permission that doesn't start with 'work_orders.details', user is NOT a field conductor
        permission_codes.none? { |code| !code.start_with?('work_orders.details') }
      end
    end
  end
end
