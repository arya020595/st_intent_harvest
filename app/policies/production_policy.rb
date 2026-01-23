# frozen_string_literal: true

class ProductionPolicy < ApplicationPolicy
  # Permission codes:
  # - production.index
  # - production.show
  # - production.create
  # - production.update
  # - production.destroy

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
    'production'
  end

  class Scope < ApplicationPolicy::Scope
    # Inherits default scope behavior

    private

    def permission_resource
      'production'
    end
  end
end
