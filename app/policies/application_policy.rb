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

  # Class method - shared helper for extracting resource names
  # Handles:
  # - Class (authorize ::WorkOrder) -> "WorkOrder"
  # - Instance (@work_order) -> "WorkOrder"
  # - Symbol/String (authorize :dashboard) -> "Dashboard"
  # - ActiveRecord::Relation (scope.klass) -> "WorkOrder"
  def self.extract_resource_name(input)
    if input.is_a?(Class)
      input.name
    elsif input.is_a?(String) || input.is_a?(Symbol)
      input.to_s.camelize
    elsif input.respond_to?(:model_name)
      input.model_name.name
    elsif input.respond_to?(:klass) && (klass = input.klass)
      klass.name
    else
      input.class.name
    end
  end

  private

  def has_permission?(action)
    permission_checker.allowed?(action, resource_name)
  end

  def permission_checker
    @permission_checker ||= PermissionChecker.new(user)
  end

  def resource_name
    self.class.extract_resource_name(record)
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
      ApplicationPolicy.extract_resource_name(scope)
    end
  end
end
