# frozen_string_literal: true

module MasterData
  class MillPolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.mills.index
    # - master_data.mills.show
    # - master_data.mills.create
    # - master_data.mills.update
    # - master_data.mills.destroy

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
      'master_data.mills'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.mills'
      end
    end
  end
end
