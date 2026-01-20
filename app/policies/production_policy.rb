# frozen_string_literal: true

class ProductionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?
    user.has_permission?('production.index')
  end

  def show?
    user.has_permission?('production.index')
  end

  def new?
    user.has_permission?('production.create')
  end

  def create?
    user.has_permission?('production.create')
  end

  def edit?
    user.has_permission?('production.update')
  end

  def update?
    user.has_permission?('production.update')
  end

  def destroy?
    user.has_permission?('production.delete')
  end

  # Align delete confirmation permission with destroy?
  def confirm_delete?
    destroy?
  end
end
