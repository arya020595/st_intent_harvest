# frozen_string_literal: true

# Prevent accidental asset precompilation in development
# This task overrides the default assets:precompile task to warn developers
if Rails.env.development?
  Rake::Task['assets:precompile'].clear if Rake::Task.task_defined?('assets:precompile')

  namespace :assets do
    desc 'Precompile assets (with development warning)'
    task precompile: :environment do
      puts "\n" + ('=' * 80)
      puts '⚠️  WARNING: You are trying to precompile assets in DEVELOPMENT mode!'
      puts('=' * 80)
      puts
      puts 'This is usually a MISTAKE and can cause issues:'
      puts '  • Precompiled assets take priority over source files'
      puts '  • Changes to JS/CSS won\'t be reflected until you precompile again'
      puts '  • Development becomes slower and debugging harder'
      puts
      puts 'In development, Rails serves assets dynamically from app/assets/'
      puts 'and app/javascript/ - no precompilation needed!'
      puts
      puts 'If you really need to test precompilation:'
      puts '  RAILS_ENV=production rails assets:precompile'
      puts
      puts 'To clean up precompiled assets in development:'
      puts '  rails assets:clobber'
      puts '  # or manually: rm -rf public/assets tmp/cache/assets'
      puts
      puts('=' * 80)
      puts

      print 'Do you really want to continue? (yes/NO): '
      response = $stdin.gets.chomp.downcase

      unless response == 'yes'
        puts '✅ Aborted. Good choice!'
        abort
      end

      puts '⚠️  Continuing with asset precompilation in development...'
      # Call the original Sprockets task
      Rake::Task['assets:environment'].invoke
      Rake::Task['assets:precompile:all'].invoke
    end
  end
end
