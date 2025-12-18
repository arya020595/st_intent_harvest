# frozen_string_literal: true

module WorkOrders
  class MandayPolicy < ApplicationPolicy
    # Permission codes:
    # - work_orders.mandays.index
    # - work_orders.mandays.show
    # - work_orders.mandays.new
    # - work_orders.mandays.create
    # - work_orders.mandays.edit
    # - work_orders.mandays.update
    # - work_orders.mandays.destroy
    private

    def permission_resource
      'work_orders.mandays'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'work_orders.mandays'
      end
    end
  end
end
