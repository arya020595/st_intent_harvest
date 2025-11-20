# frozen_string_literal: true

module WorkOrders
  class PayCalculationPolicy < ApplicationPolicy
    # Permission codes:
    # - work_orders.pay_calculations.index
    # - work_orders.pay_calculations.show
    # - work_orders.pay_calculations.new
    # - work_orders.pay_calculations.create
    # - work_orders.pay_calculations.edit
    # - work_orders.pay_calculations.update
    # - work_orders.pay_calculations.destroy
    # - work_orders.pay_calculations.worker_detail

    # Allow viewing worker details with custom permission
    def worker_detail?
      user.has_permission?(build_permission_code('worker_detail'))
    end

    private

    def permission_resource
      'work_orders.pay_calculations'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'work_orders.pay_calculations'
      end
    end
  end
end
