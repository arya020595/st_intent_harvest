# frozen_string_literal: true

# AppLogger - Universal structured logger for all Rails components
#
# Usage anywhere in the application:
#   AppLogger.info('User created', context: 'UserService', user_id: user.id)
#   AppLogger.error('Operation failed', context: self.class.name, error: e.message)
#   AppLogger.service_start('CreateWorkOrder', context: self.class.name, params: { work_order_id: 123 })
#   AppLogger.service_success('CreateWorkOrder', context: self.class.name, duration: 1.5, result: work_order.id)
#
# The logger automatically includes:
# - Timestamp
# - Log level
# - Context (class/service name)
# - Current user ID (if available via Current.user)
# - Custom data
#
# Format:
# - Development: Human-readable with structured data
# - Production: JSON format for log aggregation
class AppLogger
  class << self
    # Log informational messages
    # @param message [String] The log message
    # @param data [Hash] Additional context data (include context: 'YourClass')
    def info(message, **data)
      log(:info, message, **data)
    end

    # Log warnings
    # @param message [String] The log message
    # @param data [Hash] Additional context data
    def warn(message, **data)
      log(:warn, message, **data)
    end

    # Log errors
    # @param message [String] The log message
    # @param data [Hash] Additional context data
    def error(message, **data)
      log(:error, message, **data)
    end

    # Log debug information
    # @param message [String] The log message
    # @param data [Hash] Additional context data
    def debug(message, **data)
      log(:debug, message, **data)
    end

    # Log service operation start
    # @param operation [String] Name of the operation
    # @param data [Hash] Operation parameters (will be sanitized)
    def service_start(operation, **data)
      info("Service started: #{operation}", **sanitize_params(data))
    end

    # Log service operation success
    # @param operation [String] Name of the operation
    # @param data [Hash] Result data
    def service_success(operation, **data)
      info("Service completed successfully: #{operation}", **data)
    end

    # Log service operation failure
    # @param operation [String] Name of the operation
    # @param error [Exception, String, Array] Error that occurred
    # @param data [Hash] Additional context
    def service_failure(operation, error:, **data)
      error_data = {
        error_message: case error
                       when Exception then error.message
                       when Array then error.join(', ')
                       else error.to_s
                       end,
        error_class: error.class.name,
        **data
      }
      error_data[:backtrace] = error.backtrace.first(5) if error.is_a?(Exception)

      error("Service failed: #{operation}", **error_data)
    end

    private

    # Core logging method
    def log(level, message, **data)
      log_data = build_log_data(message, **data)

      case level
      when :info
        Rails.logger.info(format_log(log_data))
      when :warn
        Rails.logger.warn(format_log(log_data))
      when :error
        Rails.logger.error(format_log(log_data))
      when :debug
        Rails.logger.debug(format_log(log_data))
      end
    end

    # Build structured log data
    def build_log_data(message, **data)
      {
        message: message,
        context: data.delete(:context) || 'Application',
        user_id: current_user_id,
        timestamp: Time.current.iso8601
      }.merge(data)
    end

    # Format log output based on environment
    def format_log(data)
      if Rails.env.production?
        data.to_json
      else
        format_readable(data)
      end
    end

    # Human-readable format for development
    def format_readable(data)
      base = "[#{data[:context]}] #{data[:message]}"
      metadata = data.except(:context, :message, :timestamp)
                     .map { |k, v| "#{k}=#{format_value(v)}" }
                     .join(' | ')

      metadata.empty? ? base : "#{base} | #{metadata}"
    end

    # Format values for readable output
    def format_value(value)
      case value
      when Hash
        value.inspect
      when Array
        value.inspect
      else
        value.to_s
      end
    end

    # Sanitize sensitive parameters
    def sanitize_params(params)
      sensitive_keys = %i[password password_confirmation token secret api_key]
      params.transform_values do |value|
        if value.is_a?(Hash)
          value.except(*sensitive_keys)
        else
          value
        end
      end
    end

    # Get current user ID from Current context
    def current_user_id
      Current.user&.id
    rescue StandardError
      nil
    end
  end
end
