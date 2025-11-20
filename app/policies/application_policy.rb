# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.has_permission?(build_permission_code('index'))
  end

  def show?
    user.has_permission?(build_permission_code('show'))
  end

  def create?
    user.has_permission?(build_permission_code('create'))
  end

  def new?
    create?
  end

  def update?
    user.has_permission?(build_permission_code('update'))
  end

  def edit?
    update?
  end

  def destroy?
    user.has_permission?(build_permission_code('destroy'))
  end

  private

  # Build full permission code from action
  # @param action [String] The action (e.g., 'index', 'show', 'create', 'update', 'destroy')
  # @return [String] Full permission code (e.g., 'admin.users.index')
  def build_permission_code(action)
    "#{permission_resource}.#{action}"
  end

  # Override this method in subclasses to map to correct permission resource
  # @return [String] Format: "namespace.resource" (e.g., "admin.users", "workorders.orders")
  def permission_resource
    raise NotImplementedError, "#{self.class.name} must implement #permission_resource"
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(build_permission_code('index'))
        scope.all
      else
        scope.none
      end
    end

    private

    def build_permission_code(action)
      "#{permission_resource}.#{action}"
    end

    # Override this in subclass Scopes
    def permission_resource
      raise NotImplementedError, "#{self.class.name} must implement #permission_resource"
    end
  end
end
