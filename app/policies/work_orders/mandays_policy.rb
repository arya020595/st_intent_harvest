# frozen_string_literal: true

module WorkOrders
  class MandayPolicy < ApplicationPolicy
    # Permission codes:
    # - work_order_manday.index
    # - work_order_manday.show
    # - work_order_manday.new
    # - work_order_manday.create
    # - work_order_manday.edit
    # - work_order_manday.update
    # - work_order_manday.destroy
    private

    def permission_resource
      'work_order_manday'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'work_order_manday'
      end
    end
  end
end
dw
