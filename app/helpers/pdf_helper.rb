# frozen_string_literal: true

module PdfHelper
  # Embeds an image from app/assets/images as a base64 data URI so Grover/Chromium can render it
  # without needing to resolve the asset pipeline or perform network requests.
  #
  # filename: the image file inside app/assets/images (e.g. 'intent-harvest-logo.png')
  # options:  optional :alt and :style attributes
  def inline_image_base64(filename, **options)
    path = Rails.root.join('app', 'assets', 'images', filename)
    return content_tag(:span, "(missing image #{filename})") unless File.exist?(path)

    ext = File.extname(filename).delete('.').downcase
    mime = case ext
           when 'png' then 'image/png'
           when 'jpg', 'jpeg' then 'image/jpeg'
           when 'webp' then 'image/webp'
           when 'gif' then 'image/gif'
           else 'image/png'
           end

    data = Base64.strict_encode64(File.binread(path))
    alt  = ERB::Util.html_escape(options[:alt] || File.basename(filename, '.*').tr('_-', ' ').capitalize)
    style = ERB::Util.html_escape(options[:style]) if options[:style]

    tag.img(src: "data:#{mime};base64,#{data}", alt: alt, style: style)
  rescue => e
    Rails.logger.error "inline_image_base64 error for #{filename}: #{e.message}"
    content_tag(:span, "(image error #{filename})")
  end
end