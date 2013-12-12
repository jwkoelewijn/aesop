require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'lib', 'aesop', 'dispatchers', 'log_dispatcher')

describe Aesop::Dispatchers::LogDispatcher do
  let(:file_stub){ double() }

  it 'can dispatch exceptions' do
    subject.methods.map{|m| m.to_s}.should include "dispatch_exception"
  end

  it 'knows how to find the configuration' do
    subject.methods.map{|m| m.to_s}.should include "configuration"
  end

  it 'uses the aesop-logger to dispatch the messages at info level' do
    Aesop::Logger.should_receive(:info).with( Exception.to_s )
    subject.dispatch_exception( Exception.new )
  end
end
