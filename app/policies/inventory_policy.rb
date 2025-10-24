# frozen_string_literal: true

class InventoryPolicy < ApplicationPolicy
  # Inherits all default behavior from ApplicationPolicy
  # Only override if you need custom logic for specific actions

  class Scope < ApplicationPolicy::Scope
    # Inherits default scope behavior
    # Override only if you need custom filtering logic
    # def resolve
    #   if user.admin?
    #     scope.all
    #   else
    #     scope.where(block_id: user.block_ids)
    #   end
    # end
  end
end
