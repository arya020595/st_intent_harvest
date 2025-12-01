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
    # Clear any stored location to prevent redirect issues
    stored_location = stored_location_for(resource)

    stored_location || send(resource.first_accessible_path)
  end

  # Override Devise method to redirect after sign out
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  # Handle unauthorized access attempts
  # For Turbo requests: Show flash message and close modals
  # For HTML requests: Redirect to safe location
  def user_not_authorized
    message = 'You are not authorized to perform this action.'

    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: [
          turbo_stream.update('modal', ''),
          turbo_stream.append('flash_messages', partial: 'shared/flash'),
          turbo_stream.action(:hide_modals, '')
        ]
      end
      format.html do
        flash[:alert] = message
        redirect_to safe_redirect_path, allow_other_host: true
      end
    end
  end

  # Determine safe redirect path to avoid redirect loops
  def safe_redirect_path
    if request.referrer.present? && request.referrer != request.url
      request.referrer
    else
      send(current_user.first_accessible_path)
    end
  end
end
