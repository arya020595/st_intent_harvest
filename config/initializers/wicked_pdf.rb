WickedPdf.configure do |config|
  # Use the binary provided by wkhtmltopdf-binary gem
  # This will automatically find the correct binary for your platform
  config.enable_local_file_access = true
end
