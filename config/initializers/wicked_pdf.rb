WickedPdf.configure do |config|
  config.executable = '/usr/bin/wkhtmltopdf'   # update path if needed
  config.enable_local_file_access = true
end
