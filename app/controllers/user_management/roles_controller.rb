# frozen_string_literal: true

module UserManagement
  class RolesController < ApplicationController
    include RansackMultiSort
    include SoftDeletableController

    before_action :set_role, only: %i[show edit update destroy confirm_delete]

    def index
      authorize Role, policy_class: UserManagement::RolePolicy

      apply_ransack_search(policy_scope(Role, policy_scope_class: UserManagement::RolePolicy::Scope).order(id: :desc))
      @pagy, @roles = paginate_results(@q.result)
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

      respond_to do |format|
        if @role.save
          format.turbo_stream do
            flash.now[:notice] = 'Role was successfully created.'
          end
          format.html { redirect_to user_management_roles_path, notice: 'Role was successfully created.' }
          format.json { render :show, status: :created, location: @role }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'form', locals: { role: @role })
          end
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @role.errors, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @role, policy_class: UserManagement::RolePolicy
    end

    def update
      authorize @role, policy_class: UserManagement::RolePolicy

      respond_to do |format|
        if @role.update(role_params)
          format.turbo_stream do
            flash.now[:notice] = 'Role was successfully updated.'
          end
          format.html { redirect_to user_management_roles_path, notice: 'Role was successfully updated.' }
          format.json { render :show, status: :ok, location: @role }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'form', locals: { role: @role })
          end
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @role.errors, status: :unprocessable_entity }
        end
      end
    end

    def confirm_delete
      authorize @role, policy_class: RolePolicy

      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to user_management_roles_path
      end
    end

    def destroy
      authorize @role, policy_class: UserManagement::RolePolicy
      super
    end

    def restore
      @role = Role.with_discarded.find(params[:id])
      authorize @role, policy_class: UserManagement::RolePolicy
      super
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
