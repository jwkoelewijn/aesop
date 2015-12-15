require File.join( File.dirname(__FILE__), '..', 'spec_helper')

describe Aesop::Aesop do
  subject{ Aesop::Aesop.instance }

  context 'configuration' do
    it 'calls load configuration on initialization' do
      subject.should_receive(:load_configuration)
      bootloader_double = double
      bootloader_double.stub(:boot)
      Aesop::Bootloader.stub(:new).and_return(bootloader_double)
      Aesop::Aesop.instance.init
    end

    it 'loads default config when no config file exists' do
      File.stub(:exist?).and_return(false)
      config_location = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'init.rb'))
      subject.should_receive(:load).with(config_location)
      subject.load_configuration
    end

    it 'loads config file when it exists' do
      File.stub(:exist?).and_return(true)
      config_location = File.expand_path('config/aesop.rb')
      subject.should_receive(:load).with(config_location)
      subject.load_configuration
    end

    it 'can receive a block' do
      expect do |block|
        Aesop.configuration(&block)
      end.to yield_with_args(configatron)
    end

    it 'returns the configuration if no block is given' do
      Aesop.configuration.should == configatron
    end
  end

  it 'exists' do
    subject.should_not be_nil
  end

  context 'initialization' do
    it 'boots using the bootloader' do
      Aesop::Bootloader.any_instance.should_receive(:boot)
      subject.init
    end

    describe '#redis_options' do
      let(:opts){ subject.redis_options }

      it 'configures a redis socket path if its configured' do
        redis_conf = double
        allow(redis_conf).to receive(:path).and_return('test')
        allow(redis_conf).to receive(:password).and_return('')
        allow(subject.configuration).to receive(:redis).and_return(redis_conf)

        expect(opts).to     have_key(:path)
        expect(opts).to_not have_key(:host)
        expect(opts).to_not have_key(:port)
        expect(opts[:path]).to eq 'test'
      end

      it 'merges the redis password when it is given' do
        password = "pa55word"
        redis_conf = double
        redis_conf.stub(:host)
        redis_conf.stub(:port)
        allow(redis_conf).to receive(:path).and_return(nil)
        redis_conf.should_receive(:password).and_return(password)
        subject.configuration.stub(:redis).and_return(redis_conf)

        opts.should have_key(:password)
        opts[:password].should == password
      end
    end
  end

  context 'exceptions' do
    before :all do
      create_deploy_file(Time.now)
      Aesop::Aesop.instance.init
    end

    let(:exception){ Exception.new }
    let(:internal_exception){ Aesop::RedisConnectionException.new }

    before :each do
      subject.redis.stub(:get).and_return(nil)
      subject.redis.stub(:set)
    end

    it 'raises an RedisConnectionException when a redis exception occurs' do
      subject.instance_variable_set(:@redis, nil)
      Redis.stub(:new){ raise RuntimeError.new }
      lambda{subject.redis}.should raise_error( Aesop::RedisConnectionException )
    end

    it 'reconnectes when not connected to redis anymore' do
      subject.redis.client.stub(:connected?).and_return(false)
      expect(Redis).to receive(:new).and_call_original
      subject.redis
    end

    it 'dispatches each and every exception when an array is provided' do
      exceptions = []
      5.times do
        exceptions << exception
      end
      subject.should_receive(:catch_exception).with(exception).exactly(5).times
      subject.catch_exceptions( exceptions )
    end

    it 'throws an error when #catch_exceptions is not called with an array' do
      lambda{ subject.catch_exceptions( exception )}.should raise_error( Aesop::IllegalArgumentException )
    end

    it 'has a method to to register exceptions' do
      subject.public_methods.map{|m| m.to_s}.should include 'catch_exception'
    end

    it 'checks to see if an exception should be dispatched' do
      subject.should_receive(:should_dispatch?).with(exception)
      subject.catch_exception( exception )
    end

    it 'checks if an exception is excluded from dispatching' do
      subject.should_receive(:is_excluded?).with(exception)
      subject.catch_exception( exception )
    end

    it 'does not dispatch when the exception is excluded' do
      subject.stub(:is_excluded?).and_return(true)
      subject.should_dispatch?(exception).should be_false
    end

    it 'does dispatch when the exception is not excluded' do
      subject.stub(:is_excluded?).and_return(false)
      subject.should_receive(:within_window?).with(exception).and_return(true)
      subject.should_receive(:retrieve_exception_count).with(exception).and_return(11)
      subject.should_receive(:exception_count_threshold).with(exception).and_return(10)
      subject.should_dispatch?(exception).should be_true
    end

    it 'reads the excluded exceptions from the configuration' do
      config_double = double("Configuration")
      config_double.should_receive(:excluded_exceptions)
      subject.stub(:configuration){ config_double }
      subject.is_excluded?(exception)
    end

    it 'ignores exceptions from the excluded list' do
      config_double = double("Configuration")
      config_double.should_receive(:excluded_exceptions).and_return( [ArgumentError] )
      subject.stub(:configuration){ config_double }
      subject.is_excluded?( ArgumentError.new ).should be_true
    end

    it 'checks if an exception is an internal exception' do
      subject.should_receive(:internal_exception?).with(exception)
      subject.catch_exception( exception )
    end

    it 'knows when an exception is internal' do
      subject.internal_exception?(exception).should be_false
    end

    it 'knows when an exception is external' do
      subject.internal_exception?( internal_exception ).should be_true
    end

    it 'always dispatches Aesop exceptions' do
      subject.stub(:exception_already_dispatched?).and_return(false)
      subject.should_receive(:dispatch_exception).with( internal_exception )
      subject.catch_exception(internal_exception)
    end

    it 'checks if the exception already occurred' do
      subject.should_receive(:retrieve_exception_count).with(exception)
      subject.should_dispatch?( exception )
    end

    it 'uses the exception threshold to determine whether the window is open' do
      subject.should_receive(:exception_time_threshold).with(exception).and_return(3600)
      subject.within_window?(exception)
    end

    it 'checks if the time window is open to dispatch' do
      subject.should_receive(:within_window?).with(exception)
      subject.should_dispatch?( exception )
    end

    it 'retrieves the deployment time to determine if the exception should be dispatched' do
      subject.should_receive(:retrieve_deployment_time)
      subject.should_dispatch?( exception )
    end

    it 'uses the exception_prefix when retrieving the exception' do
      subject.should_receive(:exception_prefix).and_return("aesop:exceptions")
      subject.retrieve_exception_count(exception)
    end

    it 'uses the exception_prefix when storing the exception occurrence' do
      subject.should_receive(:exception_prefix).and_return("aesop:exceptions")
      subject.store_exception_occurrence(exception)
    end

    it 'uses the exception count threshould when determining whether the occurrence should be dispatched' do
      subject.stub(:within_window?).and_return(true)
      subject.stub(:retrieve_exception_count).and_return(5)
      subject.should_receive(:exception_count_threshold).with(exception).and_return(10)
      subject.should_dispatch?(exception)
    end

    it 'does not dispatch when the amount of occurrences is smaller than the threshold' do
      subject.should_not_receive(:dispatch_exception)
      subject.should_receive(:within_window?).with(exception).and_return(true)
      subject.should_receive(:retrieve_exception_count).with(exception).and_return(5)
      subject.should_receive(:exception_count_threshold).with(exception).and_return(10)
      subject.catch_exception(exception)
    end

    it 'dispatches when the amount of occurrences is greater then the threshold' do
      subject.should_receive(:dispatch_exception).with(exception)
      subject.should_receive(:within_window?).with(exception).and_return(true)
      subject.should_receive(:retrieve_exception_count).with(exception).and_return(11)
      subject.should_receive(:exception_count_threshold).with(exception).and_return(10)
      subject.catch_exception(exception)
    end

    it 'looks up the exception in redis' do
      subject.redis.should_receive(:get).with("aesop:exceptions:#{exception.class.to_s}:count")
      subject.retrieve_exception_count( exception )
    end

    it 'records the occurrence of the exception while within the window' do
      subject.should_receive(:within_window?).with(exception).and_return(false)
      subject.should_receive(:store_exception_occurrence).with(exception)
      subject.catch_exception(exception)
    end

    it 'records the occorrence of the exception while outside the window' do
      subject.should_receive(:within_window?).with(exception).and_return(true)
      subject.should_receive(:store_exception_occurrence).with(exception)
      subject.catch_exception(exception)
    end

    it 'increments the number of occurrences of an exception when stored' do
      subject.redis.should_receive(:incr).with("aesop:exceptions:#{exception.class.to_s}:count")
      subject.catch_exception(exception)
    end

    it 'checks if the exception has been dispatched yet' do
      subject.stub(:within_window?).and_return(true)
      subject.stub(:retrieve_exception_count).and_return(100)
      subject.stub(:exception_count_treshold).and_return(10)

      subject.should_receive(:exception_already_dispatched?).with(exception)
      subject.should_dispatch?(exception)
    end

    it 'does not dispatch the exception when it has already been dispatched' do
      subject.stub(:within_window?).and_return(true)
      subject.stub(:retrieve_exception_count).and_return(100)
      subject.stub(:exception_count_treshold).and_return(10)

      subject.stub(:exception_already_dispatched?).and_return(true)
      subject.should_dispatch?(exception).should be_false
    end

    it 'dispatches the exception when it should be dispatched' do
      subject.should_receive(:should_dispatch?).with(exception).and_return(true)
      subject.should_receive(:dispatch_exception).with(exception)
      subject.catch_exception(exception)
    end

    it 'records the dispatching of the exception' do
      subject.should_receive(:record_exception_dispatch).with(exception)
      subject.dispatch_exception(exception)
    end

    it 'stores the time of dispatch when an exception is dispatched' do
      subject.redis.should_receive(:set).with("aesop:exceptions:#{exception.class.to_s}:dispatched", anything())
      subject.dispatch_exception(exception)
    end

    it 'invokes the dispatcher when the exception should be dispatched' do
      Aesop::Dispatcher.instance.should_receive(:dispatch_exception).with(exception)
      subject.dispatch_exception(exception)
    end
  end
end
