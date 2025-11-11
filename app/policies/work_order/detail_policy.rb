# frozen_string_literal: true

class WorkOrder::DetailPolicy < ApplicationPolicy
  # Custom action for marking work order as complete (ongoing -> pending)
  def mark_complete?
    has_permission?(:mark_complete)
  end

  def edit?
    editable?
  end

  def update?
    editable?
  end

  private

  def editable?
    record.work_order_status.in?(%w[ongoing amendment_required])
  end

  class Scope < ApplicationPolicy::Scope
  end
end
