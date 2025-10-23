# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    has_permission?(:read)
  end

  def show?
    has_permission?(:read)
  end

  def create?
    has_permission?(:create)
  end

  def new?
    create?
  end

  def update?
    has_permission?(:update)
  end

  def edit?
    update?
  end

  def destroy?
    has_permission?(:destroy)
  end

  private

  def has_permission?(action)
    permission_checker.allowed?(action, resource_name)
  end

  def permission_checker
    @permission_checker ||= PermissionChecker.new(user)
  end

  def resource_name
    record.class.name
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if permission_checker.allowed?(:read, resource_name)
        scope.all
      else
        scope.none
      end
    end

    private

    def permission_checker
      @permission_checker ||= PermissionChecker.new(user)
    end

    def resource_name
      scope.name
    end
  end
end
