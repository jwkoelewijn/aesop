require 'singleton'

class Aesop::Aesop
  include Singleton
  include ::Aesop

  def init
    load_configuration
    Aesop::Bootloader.new.boot
  end

  def load_configuration
    config_file = if File.exist?("config/aesop.rb")
      File.expand_path("config/aesop.rb")
    else
      File.expand_path(File.join( File.dirname(__FILE__), '..', '..', 'config', 'init.rb'))
    end
    load config_file
    Aesop::Logger.debug("Loaded config in #{config_file}")
  end

  def catch_exceptions( exceptions )
    if exceptions.is_a?(Array)
      exceptions.each{ |e| catch_exception(e) }
    else
      raise IllegalArgumentException.new("#catch_exceptions should be called with an Array as argument, maybe use #catch_exception instead?")
    end
  end

  def catch_exception(exception)
    store_exception_occurrence(exception)
    if should_dispatch?(exception)
      dispatch_exception(exception)
    end
  end

  def should_dispatch?(exception)
    return false if is_excluded?(exception) || exception_already_dispatched?(exception)
    return true if internal_exception?(exception)
    current_amount = retrieve_exception_count(exception)
    within_window?(exception) && (current_amount >= exception_count_threshold(exception))
  end

  def internal_exception?(exception)
    parts = exception.class.name.split("::")
    res = (parts.size > 1 && parts.first == "Aesop")
    Aesop::Logger.debug("#{exception.class.to_s} is #{res ? "": "not "}an internal exception and will #{res ? "" : "not "}be dispatched right away")
    res
  end

  def exception_count_threshold(exception)
    configuration.exception_count_threshold
  end

  def record_exception_dispatch(exception)
    redis.set( "#{exception_prefix}:#{exception.class.to_s}:dispatched", Time.now.to_i )
  end

  def dispatch_exception(exception)
    record_exception_dispatch(exception)
    Aesop::Dispatcher.instance.dispatch_exception(exception)
  end

  def exception_already_dispatched?(exception)
    res = !redis.get( "#{exception_prefix}:#{exception.class.to_s}:dispatched" ).nil?
    Aesop::Logger.debug("#{exception.class.to_s} has #{res ? "already" : "not yet"} been dispatched")
    res
  end

  def retrieve_exception_count(exception)
    res = redis.get( "#{exception_prefix}:#{exception.class.to_s}:count" ).to_i
    Aesop::Logger.debug("This is occurrence number #{res} of #{exception.class.to_s}")
    res
  end

  def exception_prefix
    configuration.exception_prefix
  end

  def within_window?( exception )
    res = if deployed_time = retrieve_deployment_time
      (Time.now - deployed_time) < exception_time_threshold(exception)
    else
      false
    end
    Aesop::Logger.debug("#{exception.class.to_s} is#{res ? " " : " not "}within the window")
    res
  end

  def is_excluded?( exception )
    res = if (exceptions = configuration.excluded_exceptions)
      exceptions.include?( exception.class )
    else
      false
    end
    Aesop::Logger.debug( "#{exception.class.to_s} is#{res ? " " : " not "}excluded")
    res
  end

  def exception_time_threshold( exception )
    configuration.exception_time_threshold
  end

  def retrieve_deployment_time
    timestamp = redis.get( configuration.deployment_key ).to_i
    Time.at(timestamp)
  end

  def store_exception_occurrence(exception)
    redis.incr( "#{exception_prefix}:#{exception.class.to_s}:count" )
  end

  def redis_options
    options = {
      :host => configuration.redis.host,
      :port => configuration.redis.port,
    }
    if (password = configuration.redis.password) && !password.empty?
      options.merge!(:password => password)
    end
    options
  end

  def redis
    if @redis.nil? || (@redis.client && !@redis.client.connected?)
      begin
        @redis = Redis.new(redis_options)
        @redis.select( configuration.redis.database )
      rescue => e
        raise RedisConnectionException.new( e )
      end
    end
    @redis
  end
end
