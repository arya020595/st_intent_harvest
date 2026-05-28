# frozen_string_literal: true

class BiDashboardController < ApplicationController
  # Add authorization if your app requires it, e.g. Pundit or custom checks
  def index
    @powerbi_dashboard_url = ENV.fetch('LINK_BI_DASHBOARD', nil)
  end
end
