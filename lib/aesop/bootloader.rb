class Aesop::Bootloader
  include ::Aesop

  def boot
    load_dispatchers
    begin
      if time = determine_latest_deploy_time
        Aesop::Logger.info("Last deployment was at #{Time.at(time)}")
        store_timestamp( time )
      end
    rescue => e
      raise Aesop::BootloaderException.new(e)
    end
  end

  def determine_latest_deploy_time
    file_time = read_deploy_time
    redis_time = read_current_timestamp

    if file_time
      if redis_time > 0
        reset_exceptions if file_time > redis_time
        [redis_time, file_time].max
      else
        reset_exceptions
        file_time
      end
    else
      redis_time ? redis_time : Time.now.to_i
    end
  end

  def read_deploy_time
    if File.exists?(deployment_file)
      File.open(deployment_file) do |file|
        file.read.to_i
      end
    else
      return nil
    end
  end

  def load_dispatchers
    begin
      current_dir = File.dirname(__FILE__)
      Dir["#{current_dir}/dispatchers/**/*.rb"].each do |file|
        require File.expand_path(file)
      end
    rescue => e
      raise DispatcherLoadException.new(e)
    end
  end

  def read_current_timestamp
    redis.get( configuration.deployment_key ).to_i
  end

  def store_timestamp( time )
    redis.set( configuration.deployment_key, time.to_i )
  end

  def deployment_file
    self.configuration.deployment_file
  end

  def reset_exceptions
    Aesop::Logger.debug("Resetting stored exception occurrences")
    redis.keys( "#{configuration.exception_prefix}:*" ).each do |key|
      redis.del key
    end
  end

  def redis
    Aesop.instance.redis
  end
end
