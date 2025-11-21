# frozen_string_literal: true

# Module for handling AASM transition errors with user-friendly messages
# Follows Single Responsibility Principle by isolating error handling logic
# Can be included in any service that performs AASM transitions
module AasmErrorHandler
  extend ActiveSupport::Concern

  private

  # Handle AASM::InvalidTransition errors with user-friendly messages
  # @param error [AASM::InvalidTransition] The AASM error
  # @param model [ApplicationRecord] The model that failed transition
  # @param context [String] Context for logging (usually class name)
  # @return [String] User-friendly error message
  def handle_aasm_error(error, model, context: self.class.name)
    log_aasm_error(error, model, context)

    if guard_callback_failed?(error)
      model.respond_to?(:guard_failure_message) ? model.guard_failure_message : default_guard_message
    else
      "Cannot transition work order: #{error.message}"
    end
  end

  # Check if the error is due to a failed guard callback
  # @param error [AASM::InvalidTransition] The AASM error
  # @return [Boolean] true if guard callback failed
  def guard_callback_failed?(error)
    error.message.include?('Failed callback(s)')
  end

  # Log AASM transition error
  # @param error [AASM::InvalidTransition] The AASM error
  # @param model [ApplicationRecord] The model that failed transition
  # @param context [String] Context for logging
  def log_aasm_error(error, model, context)
    AppLogger.error(
      'AASM transition failed',
      context: context,
      error_class: error.class.name,
      error_message: error.message,
      model_id: model.id,
      from_state: model.aasm.current_state
    )
  end

  # Default message when guard fails but model doesn't provide custom message
  # @return [String] Default error message
  def default_guard_message
    'Cannot complete this action: Required conditions are not met.'
  end
end
