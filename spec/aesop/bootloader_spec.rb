require File.join( File.dirname(__FILE__), '..', 'spec_helper')

describe Aesop::Bootloader do
  it 'exists' do
    subject.should_not be_nil
  end

  context 'initialization' do
    it 'attempts to read a DEPLOY file when boot is called' do
      subject.should_receive :read_deploy_time
      subject.boot
    end

    it 'calls load_dispatchers on boot' do
      subject.should_receive :load_dispatchers
      subject.boot
    end

    it 'loads all files in the dispatchers directory' do
      dirname = File.dirname( File.join( File.dirname(__FILE__), '..', '..', 'lib', 'aesop', 'dispatchers' ) )
      Dir["#{dirname}/dispatchers/**/*.rb"].each do |file|
        subject.should_receive(:require).with( File.expand_path(file) )
      end
      subject.boot
    end

    it 'raises an BootloaderException when an exception occurs during bootloading' do
      subject.stub(:determine_latest_deploy_time){ raise RuntimeError.new }
      lambda{ subject.boot }.should raise_error( Aesop::BootloaderException )
    end

    it 'raises an DispatcherLoadException when an exception occurs during dispatch loading' do
      subject.stub(:require){ raise RuntimeError.new }
      lambda{ subject.load_dispatchers }.should raise_error( Aesop::DispatcherLoadException )
    end
  end

  context 'reading DEPLOY file' do
    it 'reads the configuration' do
      subject.should_receive(:configuration).at_least(1).and_return(config)
      subject.boot
    end

    it 'can retrieve the location of the deployment file' do
      subject.deployment_file
    end

    it 'does not complain when the file does not exist' do
      remove_deploy_file
      deploy_time = subject.read_deploy_time
      deploy_time.should be_nil
    end

    it 'reads a timestamp from redis' do
      subject.should_receive(:read_current_timestamp)
      subject.boot
    end

    it 'reads the timestamp from the file' do
      now = Time.now
      create_deploy_file(now)
      subject.read_deploy_time.to_i.should == now.to_i
    end

    it 'uses #determine_latest_deploy_time to determine the latest deploy time' do
      subject.should_receive(:determine_latest_deploy_time)
      subject.boot
    end

    it 'determines the latest deploy time by reading deploy file and redis' do
      subject.should_receive(:read_deploy_time)
      subject.should_receive(:read_current_timestamp)
      subject.determine_latest_deploy_time
    end

    it 'uses the time stored in the file when no time is stored in redis' do
      now = Time.now
      create_deploy_file(now)
      subject.stub(:read_current_timestamp).and_return(0)
      subject.determine_latest_deploy_time.should == now.to_i
    end

    it 'always stores the latest deploy time to redis' do
      time = Time.now - 500
      newer_time = Time.now
      create_deploy_file(time)
      subject.should_receive(:read_deploy_time).and_return(newer_time.to_i)
      subject.should_receive(:store_timestamp).with(newer_time.to_i)
      subject.boot
    end

    it 'stores a timestamp when a deployment file exists' do
      create_deploy_file
      subject.should_receive(:store_timestamp)
      subject.boot
    end

    it 'uses the configuration to lookup the exception prefix' do
      config_double = double()
      config_double.should_receive( :exception_prefix ).and_return('aesop:exceptions')
      subject.stub(:configuration).and_return(config_double)
      subject.reset_exceptions
    end

    it 'resets all exceptions when #reset_exceptions is called' do
      5.times do |i|
        subject.redis.set("#{config.exception_prefix}:SomeException#{i}:count", i)
      end

      subject.reset_exceptions
      subject.redis.keys("#{config.exception_prefix}:*").size.should == 0
    end

    it 'resets all exceptions when a new deployment has occured' do
      older_time = Time.now - 500
      newer_time = Time.now
      subject.stub(:read_deploy_time).and_return(newer_time.to_i)
      subject.stub(:read_current_timestamp).and_return(older_time.to_i)
      subject.should_receive(:reset_exceptions)
      subject.boot
    end

    it 'does not rest exceptions when the time in redis is newer' do
      older_time = Time.now - 500
      newer_time = Time.now
      subject.stub(:read_deploy_time).and_return(older_time.to_i)
      subject.stub(:read_current_timestamp).and_return(newer_time.to_i)
      subject.should_not_receive(:reset_exceptions)
      subject.boot
    end

    it 'stores the timestamp in redis in the aesop:deployment:timestamp key' do
      time = 12345
      subject.redis.should_receive(:set).with(config.deployment_key, time)
      subject.store_timestamp( time )
    end
  end
end
