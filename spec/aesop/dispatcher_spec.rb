require File.join( File.dirname(__FILE__), '..', 'spec_helper')

describe Aesop::Dispatcher do
  subject{ Aesop::Dispatcher.instance }

  def clear_instance
    #
    # Hack to be able to test if methods are called during initialization
    # We cannot just instantiate an instance, because #new is marked
    # private by the Singleton module
    #
    Singleton.__init__(Aesop::Dispatcher)
  end

  before :all do
    config.dispatchers = [:log_dispatcher]
  end

  before :each do
    clear_instance
  end

  it 'collects and registers dispatchers when initialized' do
    Aesop::Dispatcher.any_instance.should_receive(:collect_dispatchers)
    Aesop::Dispatcher.instance
  end

  it 'knows how to get the configuration' do
    subject.methods.map{|m| m.to_s}.should include "configuration"
  end

  it 'uses the configuration to see which dispatchers should be created' do
    subject.configuration.should_receive(:dispatchers).and_return([])
    subject.collect_dispatchers
  end

  it 'instantiates dispatchers from the configuration' do
    subject.should_receive(:instantiate_dispatcher).with(:log_dispatcher)
    subject.collect_dispatchers
  end

  it 'registers dispatchers' do
    subject.should_receive(:register_dispatcher)
    subject.collect_dispatchers
  end

  it 'adds dispatchers to its list when requested' do
    dispatcher_double = double("TestDispatcher")

    subject.register_dispatcher( dispatcher_double )
    subject.dispatchers.should_not be_empty
    subject.dispatchers.should include dispatcher_double
  end

  it 'dispatches the exception to each registered dispatcher' do
    exception = double()
    5.times do |i|
      dispatcher_double = double("Dispatcher #{i}")
      dispatcher_double.should_receive(:dispatch_exception).with(exception)

      subject.register_dispatcher( dispatcher_double )
    end
    subject.dispatch_exception( exception )
  end

  it 'logs exceptions that might occur in a dispatcher' do
    exception = Aesop::DispatchException.new
    Aesop::Logger.should_receive(:error).with("Exception in Aesop::Dispatchers::LogDispatcher: Exception: Aesop::DispatchException. Trying to dispatch: RuntimeError: RuntimeError")

    log_dispatcher = Aesop::Dispatchers::LogDispatcher.new
    log_dispatcher.stub(:dispatch_exception){ raise RuntimeError.new }

    subject.register_dispatcher(log_dispatcher)
    subject.dispatch_exception( exception )
  end
end
