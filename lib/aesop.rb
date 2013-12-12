require "aesop/version"
require "configatron"
require "aesop/configuration"
require "aesop/exceptions"
require "aesop/logger"
#Kernel.load File.join(File.dirname(__FILE__), '..', 'config', 'init.rb')

require "aesop/aesop"
require "aesop/bootloader"
require "aesop/dispatcher"
require "aesop/rails/middleware"
require "redis"
require "hiredis"

if defined?(Merb) && defined?(Merb::BootLoader)
  require "aesop/merb/merb_boot_loader"
elsif defined? Rails
  if Rails.respond_to?(:version) && Rails.version > '3'
    require "aesop/rails/railtie"
  else
    # After verison 2.0 of Rails we can access the configuration directly.
    # We need it to add dev mode routes after initialization finished.
    Aesop::Aesop.instance.init
  end
else
  Aesop::Aesop.instance.init
end
