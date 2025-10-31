# frozen_string_literal: true

class WorkOrder::ApprovalPolicy < ApplicationPolicy
  # Custom action for approving work orders (pending -> completed)
  def approve?
    has_permission?(:approve)
  end

  # Custom action for rejecting/requesting amendments (pending -> amendment_required)
  def reject?
    has_permission?(:reject)
  end

  class Scope < ApplicationPolicy::Scope
  end
end
