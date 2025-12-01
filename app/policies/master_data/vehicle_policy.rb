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

    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

    def new?
      create?
    end

    def edit?
      update?
    end

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
