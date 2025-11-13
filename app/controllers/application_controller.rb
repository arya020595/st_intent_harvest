class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  before_action :authenticate_user!
  before_action :set_current_user

  # Smart layout switching: dashboard for authenticated pages, application for public pages
  layout :set_layout

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_layout
    # Use clean layout for Devise controllers (login, signup, password reset)
    # Use dashboard layout for all other authenticated pages
    devise_controller? ? 'application' : 'dashboard/application'
  end

  def set_current_user
    Current.user = current_user
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'

    redirect_path = if request.referrer.present?
                      request.referrer
                    elsif controller_name.present?
                      # Try to redirect back to the index action of the current controller
                      { action: :index }
                    else
                      root_path
                    end

    redirect_to redirect_path
  end
end
