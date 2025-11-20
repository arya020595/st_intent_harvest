# frozen_string_literal: true

namespace :annotate do
  desc 'Print schema information for a model'
  task :model, [:model_name] => :environment do |_t, args|
    model_name = args[:model_name]

    unless model_name
      puts 'Usage: rails annotate:model[ModelName]'
      puts 'Example: rails annotate:model[WorkOrderWorker]'
      exit
    end

    begin
      model_class = model_name.constantize
      table_name = model_class.table_name

      puts "\n# == Schema Information"
      puts '#'
      puts "# Table name: #{table_name}"
      puts '#'

      # Get columns
      columns = ActiveRecord::Base.connection.columns(table_name)

      # Calculate max lengths for formatting
      max_name_length = columns.map { |c| c.name.length }.max
      max_type_length = columns.map { |c| c.type.to_s.length }.max

      columns.each do |column|
        name = column.name.ljust(max_name_length)
        type = column.type.to_s.ljust(max_type_length)

        parts = ["#  #{name} :#{type}"]

        # Add precision and scale for decimal
        if column.type == :decimal && column.precision && column.scale
          parts << "precision: #{column.precision}, scale: #{column.scale}"
        end

        # Add limit for string
        parts << "limit: #{column.limit}" if column.type == :string && column.limit

        # Add default
        parts << "default(#{column.default.inspect})" if column.default

        # Add null constraint
        parts << 'not null' unless column.null

        # Add comment
        parts << "comment: #{column.comment.inspect}" if column.comment

        puts parts.join(', ')
      end

      # Get indexes
      indexes = ActiveRecord::Base.connection.indexes(table_name)
      if indexes.any?
        puts '#'
        puts '# Indexes'
        puts '#'
        indexes.each do |index|
          columns_str = index.columns.is_a?(Array) ? index.columns.join(', ') : index.columns
          puts "#  #{index.name.ljust(50)} (#{columns_str})"
        end
      end

      # Get foreign keys
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name)
      if foreign_keys.any?
        puts '#'
        puts '# Foreign Keys'
        puts '#'
        foreign_keys.each do |fk|
          puts "#  #{fk.name.ljust(50)} (#{fk.column} => #{fk.to_table}.#{fk.primary_key})"
        end
      end

      puts '#'
    rescue NameError
      puts "Error: Model '#{model_name}' not found"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end

  desc 'Print schema information for all models'
  task all: :environment do
    # Get all model files
    model_files = Dir[Rails.root.join('app', 'models', '**', '*.rb')]

    model_files.each do |file|
      # Skip concerns and base classes
      next if file.include?('/concerns/')
      next if File.basename(file) == 'application_record.rb'

      # Get model name from file path
      relative_path = file.sub("#{Rails.root.join('app', 'models')}/", '')
      model_name = relative_path.sub('.rb', '').camelize

      begin
        model_class = model_name.constantize
        next unless model_class < ApplicationRecord

        puts "\n#{'=' * 80}"
        puts "Model: #{model_name}"
        puts '=' * 80

        Rake::Task['annotate:model'].reenable
        Rake::Task['annotate:model'].invoke(model_name)
      rescue StandardError => e
        puts "Skipping #{model_name}: #{e.message}"
      end
    end
  end
end
