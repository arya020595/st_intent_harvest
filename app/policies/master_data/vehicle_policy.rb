# frozen_string_literal: true

module MasterData
  class VehiclePolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.vehicles.index
    # - master_data.vehicles.show
    # - master_data.vehicles.new
    # - master_data.vehicles.create
    # - master_data.vehicles.edit
    # - master_data.vehicles.update
    # - master_data.vehicles.destroy

    private

    def permission_resource
      'master_data.vehicles'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.vehicles'
      end
    end
  end
end
