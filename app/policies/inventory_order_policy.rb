# frozen_string_literal: true

class InventoryOrderPolicy < ApplicationPolicy
  # Permission codes:
  # - inventory_order.index
  # - inventory_order.show
  # - inventory_order.new
  # - inventory_order.create
  # - inventory_order.edit
  # - inventory_order.update
  # - inventory_order.destroy

  def index?
    user.has_permission?('inventory.index')
  end

  def show?
    user.has_permission?('inventory.show')
  end

  def new?
    user.has_permission?('inventory.new')
  end

  def create?
    new?
  end

  def edit?
    user.has_permission?('inventory.edit')
  end

  def update?
    edit?
  end

  def destroy?
    user.has_permission?('inventory.destroy')
  end

  private

  def permission_resource
    'inventory_order'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'inventory_order'
    end
  end
end
