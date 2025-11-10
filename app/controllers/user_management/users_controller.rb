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

      # Logic to be implemented later
    end

    def edit
      authorize @user, policy_class: UserManagement::UserPolicy
    end

    def update
      authorize @user, policy_class: UserManagement::UserPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @user, policy_class: UserManagement::UserPolicy

      # Logic to be implemented later
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
