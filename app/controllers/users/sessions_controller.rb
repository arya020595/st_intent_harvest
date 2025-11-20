# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]

    # Skip authentication for login pages
    skip_before_action :authenticate_user!, only: %i[new create]

    # POST /resource/sign_in
    def create
      # Clear any existing session data before sign in
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    # DELETE /resource/sign_out
    def destroy
      # Ensure proper sign out
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out
      yield if block_given?
      respond_to_on_destroy
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end

    protected

    def respond_to_on_destroy
      # Always redirect to sign in page after sign out
      respond_to do |format|
        format.all { redirect_to new_user_session_path }
      end
    end
  end
end
