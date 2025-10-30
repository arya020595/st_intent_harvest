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

  # Derive resource name from policy class name by removing "Policy" suffix
  # Examples:
  #   WorkOrder::DetailPolicy -> "WorkOrder::Detail"
  #   WorkOrder::ApprovalPolicy -> "WorkOrder::Approval"
  #   InventoryPolicy -> "Inventory"
  def resource_name
    @resource_name ||= self.class.name.delete_suffix('Policy')
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

    # Derive resource name from policy scope class name
    # Examples:
    #   WorkOrder::DetailPolicy::Scope -> "WorkOrder::Detail"
    #   WorkOrder::ApprovalPolicy::Scope -> "WorkOrder::Approval"
    #   InventoryPolicy::Scope -> "Inventory"
    def resource_name
      @resource_name ||= self.class.name.sub(/(::Scope)?Policy\z/, '')
    end
  end
end
