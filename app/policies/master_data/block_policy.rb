# frozen_string_literal: true

module MasterData
  class BlockPolicy < ApplicationPolicy
    # Permission codes:
    # - master_data.blocks.index
    # - master_data.blocks.show
    # - master_data.blocks.new
    # - master_data.blocks.create
    # - master_data.blocks.edit
    # - master_data.blocks.update
    # - master_data.blocks.destroy

    # Define who can delete a block
    def destroy?
      # Adjust this to your actual permission logic
      true
    end

    # Define who can see the delete confirmation
    def confirm_delete?
      destroy?
    end

    private

    def permission_resource
      'master_data.blocks'
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'master_data.blocks'
      end
    end
  end
end
