# frozen_string_literal: true

module MasterData
  class CategoryPolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.categories.index
    # - master_data.categories.show
    # - master_data.categories.new
    # - master_data.categories.create
    # - master_data.categories.edit
    # - master_data.categories.update
    # - master_data.categories.destroy

    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

    private

    def permission_resource
      'master_data.categories'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.categories'
      end
    end
  end
end
