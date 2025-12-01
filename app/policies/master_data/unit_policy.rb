# frozen_string_literal: true

module MasterData
  class UnitPolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.units.index
    # - master_data.units.show
    # - master_data.units.new
    # - master_data.units.create
    # - master_data.units.edit
    # - master_data.units.update
    # - master_data.units.destroy

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
      'master_data.units'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.units'
      end
    end
  end
end
