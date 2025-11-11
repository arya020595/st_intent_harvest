# config/puma.production.rb

max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

workers ENV.fetch('WEB_CONCURRENCY', 2)

preload_app!

port ENV.fetch('PORT', 3000)
environment ENV.fetch('RAILS_ENV', 'production')

plugin :tmp_restart
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']

worker_timeout 30
worker_shutdown_timeout 30

pidfile ENV.fetch('PIDFILE', '/rails/tmp/pids/server.pid')
state_path '/rails/tmp/pids/puma.state'

stdout_redirect 'log/puma.stdout.log', 'log/puma.stderr.log', true unless ENV['RAILS_LOG_TO_STDOUT'] == 'true'
