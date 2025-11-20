# frozen_string_literal: true

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

  # Override Devise method to redirect users to their first accessible resource
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || send(resource.first_accessible_path)
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'

    # Get user's first accessible path, but avoid redirect loop
    redirect_path = if request.referrer.present? && request.referrer != request.url
                      # Redirect to previous page if it exists and is different
                      request.referrer
                    else
                      # Redirect to user's first accessible resource
                      send(current_user.first_accessible_path)
                    end

    redirect_to redirect_path, allow_other_host: true
  end
end
