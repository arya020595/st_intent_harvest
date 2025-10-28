# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    has_permission?(:index)
  end

  def show?
    has_permission?(:show)
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
    # Handle different types of records:
    # - Class (authorize ::WorkOrder) -> "WorkOrder"
    # - Instance (@work_order) -> "WorkOrder"
    # - Symbol/String (authorize :dashboard) -> "Dashboard"
    if record.is_a?(Class)
      record.name.demodulize
    elsif record.is_a?(String) || record.is_a?(Symbol)
      record.to_s.camelize.demodulize
    elsif record.respond_to?(:model_name)
      record.model_name.name.demodulize
    else
      record.class.name.demodulize
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if permission_checker.allowed?(:index, resource_name)
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
      # Handle scope which can be a Class or ActiveRecord::Relation
      if scope.is_a?(Class)
        scope.name.demodulize
      elsif scope.respond_to?(:klass) && scope.klass
        # ActiveRecord::Relation has a klass method
        scope.klass.name.demodulize
      else
        scope.name.demodulize
      end
    end
  end
end
