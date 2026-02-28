# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.traces_sample_rate = 1.0

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  # Enable sending logs to Sentry
  config.enable_logs = true
  # Patch Ruby logger to forward logs
  config.enabled_patches = [:logger]
end
