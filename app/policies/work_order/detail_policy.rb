# frozen_string_literal: true

class WorkOrder::DetailPolicy < ApplicationPolicy
  # Custom action for marking work order as complete (ongoing -> pending)
  def mark_complete?
    has_permission?(:mark_complete)
  end

  class Scope < ApplicationPolicy::Scope
  end
end
