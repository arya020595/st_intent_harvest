# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.release = ENV.fetch('SENTRY_RELEASE', nil)
  config.traces_sample_rate = 1.0

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  # Enable sending logs to Sentry
  config.enable_logs = true

  # Enable opt-in structured log subscribers (active_record + action_controller are on by default)
  config.rails.structured_logging.subscribers = {
    active_record: Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    active_job: Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }

  # Use << to append :logger patch without overriding other default patches.
  # NOTE: This forwards ALL Rails.logger calls to Sentry and can be very noisy.
  # Prefer Sentry.logger.info/error/warn for explicit, targeted logging.
  config.enabled_patches << :logger
end
