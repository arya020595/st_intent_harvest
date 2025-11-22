# frozen_string_literal: true

Grover.configure do |config|
  # Use Chrome/Chromium for PDF generation
  config.options = {
    format: 'A4',
    margin: {
      top: '1cm',
      bottom: '1cm',
      left: '1cm',
      right: '1cm'
    },
    print_background: true,
    display_header_footer: false,
    prefer_css_page_size: false,
    emulate_media: 'print',
    # Wait for network to be idle before generating PDF
    wait_until: 'networkidle2',
    # Timeout for PDF generation (30 seconds)
    timeout: 30_000
  }

  # Use system Chrome/Chromium in Docker
  # The GROVER_NO_SANDBOX environment variable is set in Dockerfile
end
