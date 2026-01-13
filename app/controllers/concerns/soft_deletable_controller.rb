# frozen_string_literal: true

# SoftDeletableController - Controller concern for soft delete actions
#
# Single Responsibility: Handles HTTP layer for soft delete operations
# Open/Closed: Configurable through class methods, works with existing patterns
# Dependency Inversion: Uses discard gem methods directly for simplicity
#
# Usage:
#   class UsersController < ApplicationController
#     include SoftDeletableController
#
#     # This overrides destroy to use soft delete
#     # Also provides restore action
#   end
#
# For controllers where resource name differs from controller name:
#   class WorkOrders::DetailsController < ApplicationController
#     include SoftDeletableController
#     self.soft_deletable_resource_name = :work_order
#   end
#
# The concern automatically:
# - Overrides destroy to use discard (soft delete)
# - Provides restore action to undiscard records
# - Works with Turbo Stream, HTML, and JSON formats
# - Maintains existing flash message patterns
#
module SoftDeletableController
  extend ActiveSupport::Concern

  included do
    class_attribute :soft_deletable_resource_name, instance_writer: false
  end

  # Soft delete a record (replaces permanent delete)
  # Uses the existing @resource instance variable set by before_action
  def destroy
    resource = find_soft_deletable_resource
    return head :not_found unless resource

    if resource.discard
      respond_to_soft_delete_success(resource, :deleted)
    else
      respond_to_soft_delete_failure(resource, :delete)
    end
  end

  # Restore a soft-deleted record
  # Route: PATCH/PUT /resources/:id/restore
  def restore
    resource = find_soft_deletable_resource_with_discarded
    return head :not_found unless resource

    if resource.undiscard
      respond_to_soft_delete_success(resource, :restored)
    else
      respond_to_soft_delete_failure(resource, :restore)
    end
  end

  private

  # Determine the resource name (e.g., 'worker', 'user', 'work_order')
  def soft_delete_resource_name
    (self.class.soft_deletable_resource_name || controller_name.singularize).to_s
  end

  # Find the resource instance variable (e.g., @worker, @user, @work_order)
  # Controllers should set this via before_action :set_resource
  def find_soft_deletable_resource
    instance_variable_get("@#{soft_delete_resource_name}")
  end

  # Find resource including discarded (for restore action)
  def find_soft_deletable_resource_with_discarded
    resource_class = soft_delete_resource_name.classify.constantize
    resource_class.with_discarded.find_by(id: params[:id])
  end

  def respond_to_soft_delete_success(resource, action)
    action_text = action == :deleted ? 'deleted' : 'restored'
    model_name = resource.class.model_name.human

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "#{model_name} was successfully #{action_text}."
      end
      format.html do
        redirect_to polymorphic_index_path(resource),
                    notice: "#{model_name} was successfully #{action_text}."
      end
      format.json { render json: resource, status: :ok }
    end
  end

  def respond_to_soft_delete_failure(resource, action)
    action_text = action == :delete ? 'delete' : 'restore'
    model_name = resource.class.model_name.human
    error_message = resource.errors.full_messages.join(', ')

    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = "Unable to #{action_text} #{model_name.downcase}: #{error_message}"
        render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash'),
               status: :unprocessable_entity
      end
      format.html do
        redirect_to polymorphic_index_path(resource),
                    alert: "Unable to #{action_text} #{model_name.downcase}: #{error_message}"
      end
      format.json { render json: { error: error_message }, status: :unprocessable_entity }
    end
  end

  # Get the index path for the resource (handles namespaced controllers)
  def polymorphic_index_path(_resource)
    # Try to use the controller's namespace if available
    if self.class.module_parent == Object
      send("#{controller_name}_path")
    else
      namespace = self.class.module_parent.name.underscore.to_sym
      send("#{namespace}_#{controller_name}_path")
    end
  rescue NoMethodError => e
    route_helper = self.class.module_parent == Object ? "#{controller_name}_path" : "#{self.class.module_parent.name.underscore}_#{controller_name}_path"

    # Log warning about missing route helper
    Rails.logger.warn "SoftDeletableController: Route helper '#{route_helper}' not found for #{self.class.name}. Falling back to root_path."

    # In development/test, raise informative error to help catch configuration issues
    if Rails.env.development? || Rails.env.test?
      raise NoMethodError,
            "Route helper '#{route_helper}' not found. Please ensure routes are properly configured for #{self.class.name}. Original error: #{e.message}"
    end

    # In production, fall back gracefully to root path
    root_path
  end
end
