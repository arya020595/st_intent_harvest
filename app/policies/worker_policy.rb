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
