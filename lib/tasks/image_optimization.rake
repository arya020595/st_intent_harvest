# frozen_string_literal: true

namespace :assets do
  desc 'Check image sizes in app/assets/images'
  task check_images: :environment do
    puts "\n🔍 Checking image sizes in app/assets/images...\n\n"

    images = Dir.glob(Rails.root.join('app', 'assets', 'images', '**', '*.{jpg,jpeg,png}'))

    if images.empty?
      puts 'No images found in app/assets/images'
      exit
    end

    # Display current sizes
    puts 'Current Image Sizes:'
    puts '-' * 80

    images.each do |image_path|
      file_size = File.size(image_path)
      file_name = image_path.sub("#{Rails.root.join('app', 'assets', 'images')}/", '')

      size_in_kb = file_size / 1024.0
      size_in_mb = size_in_kb / 1024.0

      # Color coding based on size
      if size_in_mb >= 1
        status = '⚠️  TOO LARGE'
        formatted_size = "#{size_in_mb.round(2)} MB"
      elsif size_in_kb > 500
        status = '⚠️  LARGE'
        formatted_size = "#{size_in_kb.round(2)} KB"
      else
        status = '✓'
        formatted_size = "#{size_in_kb.round(2)} KB"
      end

      puts "#{status.ljust(15)} #{formatted_size.rjust(12)} - #{file_name}"
    end

    puts "\n#{'-' * 80}"
  end

  desc 'Optimize images in app/assets/images using image_processing/vips'
  task optimize_images: :environment do
    require 'image_processing/vips'

    puts "\n🔧 Optimizing images in app/assets/images...\n\n"

    images = Dir.glob(Rails.root.join('app', 'assets', 'images', '**', '*.{jpg,jpeg,png}'))

    if images.empty?
      puts 'No images found in app/assets/images'
      exit
    end

    total_before = 0
    total_after = 0

    puts 'Optimizing images...'
    puts '-' * 80

    images.each do |image_path|
      file_name = image_path.sub("#{Rails.root.join('app', 'assets', 'images')}/", '')
      before_size = File.size(image_path)
      total_before += before_size

      # Create temp file
      temp_file = Tempfile.new(['optimized', File.extname(image_path)])

      begin
        # Optimize based on file type
        if image_path.match?(/\.(jpg|jpeg)$/i)
          # JPEG optimization: quality 85%, strip metadata
          ImageProcessing::Vips
            .source(image_path)
            .saver(quality: 85, strip: true)
            .call(destination: temp_file.path)
        elsif image_path.match?(/\.png$/i)
          # PNG optimization: use palettize for better compression
          ImageProcessing::Vips
            .source(image_path)
            .convert('png')
            .saver(palette: true, quality: 85, strip: true)
            .call(destination: temp_file.path)
        end

        # Replace original file with optimized version
        FileUtils.mv(temp_file.path, image_path)

        after_size = File.size(image_path)
        total_after += after_size

        saved = before_size - after_size
        percent = saved.positive? ? ((saved.to_f / before_size) * 100).round(1) : 0.0

        puts "✓ #{file_name}"
        puts "  Before: #{(before_size / 1024.0).round(2)} KB → After: #{(after_size / 1024.0).round(2)} KB"
        puts "  Saved: #{(saved / 1024.0).round(2)} KB (#{percent}%)"
      rescue StandardError => e
        puts "✗ #{file_name} - Error: #{e.message}"
        after_size = before_size
        total_after += after_size
      ensure
        temp_file.close
        temp_file.unlink if File.exist?(temp_file.path)
      end
      puts ''
    end

    puts '-' * 80
    total_saved = total_before - total_after
    total_percent = total_saved.positive? ? ((total_saved.to_f / total_before) * 100).round(1) : 0.0

    puts "\nTotal Before: #{(total_before / 1024.0 / 1024.0).round(2)} MB"
    puts "Total After:  #{(total_after / 1024.0 / 1024.0).round(2)} MB"
    puts "Total Saved:  #{(total_saved / 1024.0 / 1024.0).round(2)} MB (#{total_percent}%)"
    puts "\n✅ Image optimization complete!\n\n"
  end
end
