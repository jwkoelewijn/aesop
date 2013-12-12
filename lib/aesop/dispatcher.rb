require 'singleton'
module Aesop
  module Dispatchers
  end
end

class Aesop::Dispatcher
  include Singleton
  include ::Aesop

  def initialize
    collect_dispatchers
  end

  def dispatch_exception(exception)
    dispatchers.each do |dispatcher|
      begin
        Aesop::Logger.debug("#{dispatcher.class.to_s}: dispatching #{exception.class.to_s}")
        dispatcher.dispatch_exception(exception)
      rescue => e
        Aesop::Logger.error( "Exception in #{dispatcher.class.to_s}: Exception: #{exception.class.to_s}. Trying to dispatch: #{e.class.to_s}: #{e.message}" )
      end
    end
  end

  def instantiate_dispatcher( symbol )
    Aesop::Logger.debug("Instantiating #{to_classname(symbol)}")
    Aesop::Dispatchers.const_get( to_classname(symbol) ).new
  end

  def collect_dispatchers
    configuration.dispatchers.each do |dispatch_symbol|
      instance = instantiate_dispatcher( dispatch_symbol )
      register_dispatcher(instance)
    end
  end

  def register_dispatcher( dispatcher )
    dispatchers << dispatcher
  end

  def dispatchers
    @dispatchers ||= []
  end

  def to_classname(symbol)
    symbol.to_s.split(/[-_]/).map(&:capitalize).join
  end
end
