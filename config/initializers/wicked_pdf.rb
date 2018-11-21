# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md
require 'rbconfig'

if RbConfig::CONFIG['host_os'] =~ /linux/
  arch = RbConfig::CONFIG['host_cpu'] == 'x86_64' ? 'wkhtmltopdf_linux_x86' : 'wkhtmltopdf_linux_386'
elsif RbConfig::CONFIG['host_os'] =~ /darwin/
  arch = 'wkhtmltopdf_darwin_386'
else
  raise "Invalid platform. Must be running Intel-based Linux or OSX."
end

if !Rails.env.development?
  WickedPdf.config = {
    exe_path: "#{ENV['GEM_HOME']}/gems/wkhtmltopdf-binary-#{Gem.loaded_specs['wkhtmltopdf-binary'].version}/bin/wkhtmltopdf_linux_amd64"
  }
end