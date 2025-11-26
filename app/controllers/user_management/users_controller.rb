# frozen_string_literal: true

module UserManagement
  class UsersController < ApplicationController
    include RansackMultiSort

    before_action :set_user, only: %i[show edit update destroy]

    def index
      authorize User, policy_class: UserManagement::UserPolicy

      apply_ransack_search(policy_scope(User, policy_scope_class: UserManagement::UserPolicy::Scope).order(id: :desc))
      @pagy, @users = paginate_results(@q.result.includes(:role))
    end

    def show
      authorize @user, policy_class: UserManagement::UserPolicy
    end

    def new
      @user = User.new
      authorize @user, policy_class: UserManagement::UserPolicy
    end

    def create
      @user = User.new(user_params)
      authorize @user, policy_class: UserManagement::UserPolicy

      if @user.save
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = 'User created successfully.'
          end
          format.html { redirect_to user_management_users_path, notice: 'User created successfully.' }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user, policy_class: UserManagement::UserPolicy
    end

    def update
      authorize @user, policy_class: UserManagement::UserPolicy

      if @user.update(user_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = 'User updated successfully.'
          end
          format.html { redirect_to user_management_users_path, notice: 'User updated successfully.' }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def confirm_delete
      @user = User.find_by(id: params[:id])
      unless @user
        redirect_to user_management_users_path, alert: "User not found" and return
      end

      authorize @user, policy_class: UserPolicy

      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to user_management_users_path
      end
    end

    def destroy
      authorize @user, policy_class: UserManagement::UserPolicy

      if @user.destroy
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = 'User deleted successfully.'
          end
          format.html { redirect_to user_management_users_path, notice: 'User deleted successfully.' }
        end
      else
        redirect_to user_management_users_path, alert: 'Failed to delete user.'
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :email,
        :password,
        :password_confirmation,
        :name,
        :role_id
      )
    end
  end
end
