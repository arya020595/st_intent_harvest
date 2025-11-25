# frozen_string_literal: true

class WorkerPolicy < ApplicationPolicy
  # Permission codes:
  # - workers.index
  # - workers.show
  # - workers.new
  # - workers.create
  # - workers.edit
  # - workers.update
  # - workers.destroy

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
    'workers'
  end

  class Scope < ApplicationPolicy::Scope
    # Inherits default scope behavior

    private

    def permission_resource
      'workers'
    end
  end
end
