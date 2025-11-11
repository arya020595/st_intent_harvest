# frozen_string_literal: true

class WorkOrder::ApprovalPolicy < ApplicationPolicy
  # Custom action for approving work orders (pending -> completed)
  def approve?
    has_permission?(:approve)
  end

  # Custom action for requesting amendments (pending -> amendment_required)
  def request_amendment?
    has_permission?(:request_amendment)
  end

  class Scope < ApplicationPolicy::Scope
  end
end
