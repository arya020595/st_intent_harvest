# frozen_string_literal: true

# Dashboard controller for the main application dashboard
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @pending_work_orders = WorkOrder.pending.count
    @ongoing_work_orders = WorkOrder.ongoing.count
    @completed_work_orders = WorkOrder.completed.count
    @amendment_required_work_orders = WorkOrder.amendment_required.count
    
    # Recent work orders
    @recent_work_orders = WorkOrder.order(created_at: :desc).limit(10)
    
    # Optional: Add user-specific statistics if needed
    # @my_work_orders = current_user.work_orders if current_user.respond_to?(:work_orders)
  end
end
