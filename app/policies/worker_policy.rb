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
