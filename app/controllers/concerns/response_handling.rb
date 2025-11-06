# frozen_string_literal: true

# ResponseHandling Concern
# Standardized response handling for dry-monads Result objects
#
# Usage examples:
#   handle_result(result, success_path: path, error_path: path)
#   handle_result(result, success_path: path, error_action: :new)
#   handle_result(result, success_path: ->(data) { path(data[:resource]) }, error_action: :new)
#   handle_result(result, success_path: index_path, json_success_path: show_path, error_path: path)
module ResponseHandling
  extend ActiveSupport::Concern

  # Main method to handle dry-monads Result with redirect or render responses
  # Supports both HTML and JSON formats with optional separate paths for each
  def handle_result(result, success_path: nil, error_path: nil, error_action: nil, success_status: nil,
                    error_status: :unprocessable_entity, json_success_path: nil, json_error_path: nil)
    result.either(
      ->(success_value) { handle_success(success_value, success_path, success_status, json_success_path) },
      ->(error_value) { handle_error(error_value, error_path, error_action, error_status, json_error_path) }
    )
  end

  # Convenience method to handle Result with resource-based path generation
  # Automatically builds paths like resource_path(@resource) based on action
  def handle_result_for(result, resource, success_action: :index, error_action: :show)
    success_path = resource_path_for(resource, success_action)
    error_path = resource_path_for(resource, error_action)

    handle_result(result, success_path: success_path, error_path: error_path)
  end

  private

  # Handle successful result - redirects for HTML, returns JSON with redirect_url
  def handle_success(value, path = nil, status = nil, json_path = nil)
    message, data = extract_message_and_data(value)
    html_redirect_path = resolve_path(path, data) || default_success_path
    json_redirect_path = resolve_path(json_path, data) || resolve_path(path, data) || default_success_path

    respond_to do |format|
      format.html { redirect_to html_redirect_path, notice: message }
      format.json do
        render json: {
          success: true,
          message: message,
          redirect_url: url_for(json_redirect_path)
        }, status: status || :ok
      end
    end
  end

  # Handle error result - redirects or renders template for HTML, returns JSON with error
  # If error_action is provided, renders that template instead of redirecting
  def handle_error(value, path = nil, action = nil, status = :unprocessable_entity, json_path = nil)
    message = extract_message(value)

    respond_to do |format|
      if action
        format.html do
          flash.now[:alert] = message
          render action, status: status
        end
        format.json { render json: { success: false, error: message }, status: status }
      else
        html_redirect_path = path || default_error_path
        json_redirect_path = json_path || path || default_error_path

        format.html { redirect_to html_redirect_path, alert: message }
        format.json do
          render json: { success: false, error: message, redirect_url: url_for(json_redirect_path) }, status: status
        end
      end
    end
  end

  # Extract message string from various value types
  def extract_message(value)
    case value
    when String then value
    when Array then value.join(', ')
    when Hash then value[:message] || value['message'] || value.to_s
    else value.to_s
    end
  end

  # Extract both message and data from value (for lambda path resolution)
  # Returns [message, data] tuple
  def extract_message_and_data(value)
    case value
    when Hash then [value[:message] || value['message'] || value.to_s, value]
    when String then [value, nil]
    when Array then [value.join(', '), nil]
    else [value.to_s, value]
    end
  end

  # Resolve path - supports static path or dynamic Proc that receives data
  def resolve_path(path, data)
    return nil if path.nil?

    path.is_a?(Proc) ? path.call(data) : path
  end

  # Default redirect path for successful responses (override in controller if needed)
  def default_success_path
    { action: :index }
  end

  # Default redirect path for error responses (override in controller if needed)
  def default_error_path
    { action: :index }
  end

  # Generate polymorphic path based on resource and action type
  def resource_path_for(resource, action)
    case action
    when :index
      polymorphic_path(resource.class)
    when :show
      polymorphic_path(resource)
    when :edit
      edit_polymorphic_path(resource)
    when :new
      new_polymorphic_path(resource.class)
    else
      polymorphic_path(resource)
    end
  rescue StandardError
    default_success_path
  end
end
