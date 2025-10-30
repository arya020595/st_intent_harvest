# frozen_string_literal: true

module UserManagement
  class RolesController < ApplicationController
    before_action :set_role, only: %i[show edit update destroy]

    def index
      @roles = policy_scope(Role, policy_scope_class: UserManagement::RolePolicy::Scope)
      authorize Role, policy_class: UserManagement::RolePolicy
    end

    def show
      authorize @role, policy_class: UserManagement::RolePolicy
    end

    def new
      @role = Role.new
      authorize @role, policy_class: UserManagement::RolePolicy
    end

    def create
      @role = Role.new(role_params)
      authorize @role, policy_class: UserManagement::RolePolicy

      # Logic to be implemented later
    end

    def edit
      authorize @role, policy_class: UserManagement::RolePolicy
    end

    def update
      authorize @role, policy_class: UserManagement::RolePolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @role, policy_class: UserManagement::RolePolicy

      # Logic to be implemented later
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(
        :name,
        :description,
        permission_ids: []
      )
    end
  end
end
