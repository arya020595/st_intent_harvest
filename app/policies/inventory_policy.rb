# frozen_string_literal: true

class InventoryPolicy < ApplicationPolicy
  # Permission codes:
  # - inventory.index
  # - inventory.show
  # - inventory.new
  # - inventory.create
  # - inventory.edit
  # - inventory.update
  # - inventory.destroy

  def new?
    create?
  end

  def edit?
    update?
  end

  private

  def permission_resource
    'inventory'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'inventory'
    end
  end
end
