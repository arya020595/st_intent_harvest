# frozen_string_literal: true

module MasterData
  class WorkOrderRatePolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.work_order_rates.index
    # - master_data.work_order_rates.show
    # - master_data.work_order_rates.new
    # - master_data.work_order_rates.create
    # - master_data.work_order_rates.edit
    # - master_data.work_order_rates.update
    # - master_data.work_order_rates.destroy

    private

    def permission_resource
      'master_data.work_order_rates'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.work_order_rates'
      end
    end
  end
end
