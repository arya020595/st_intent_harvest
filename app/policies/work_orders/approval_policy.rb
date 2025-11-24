# frozen_string_literal: true

module WorkOrders
  class ApprovalPolicy < ApplicationPolicy
    # Permission codes:
    # - work_orders.approvals.index
    # - work_orders.approvals.show
    # - work_orders.approvals.update
    # - work_orders.approvals.approve
    # - work_orders.approvals.request_amendment

    # Custom action for approving work orders (pending -> completed)
    def approve?
      user.has_permission?(build_permission_code('approve'))
    end

    # Custom action for requesting amendments (pending -> amendment_required)
    def request_amendment?
      user.has_permission?(build_permission_code('request_amendment'))
    end

    private

    def permission_resource
      'work_orders.approvals'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'work_orders.approvals'
      end
    end
  end
end
