require File.join( File.dirname(__FILE__), "..", "spec_helper" )

describe Aesop::Logger do
  before :each do
    @logger = Aesop::Logger

    configatron.logger do |log|
      log.name       = 'aesop'
      log.level      = Aesop::Logger::WARN
      log.outputters = 'stdout'
    end

    Aesop::Logger.reset
    Aesop::Logger.stub(:configuration){ config.logger }
  end

  it 'uses configuration to set logger name' do
    config.logger.should_receive(:name).and_return('aesop')
    @logger.log
  end

  it 'uses configuration to set the outputter' do
    config.logger.should_receive(:outputters).and_return('stdout')
    @logger.log
  end

  it 'uses configuration to set the lvel' do
    config.logger.should_receive(:level).and_return(Aesop::Logger::WARN)
    @logger.log
  end

  it 'returns an object of Log4r::Logger class' do
    @logger.log.should be_a Log4r::Logger
  end

  it 'allows changing its settings' do
    @logger.level.should_not == Log4r::DEBUG
    @logger.level = Log4r::DEBUG
    @logger.level.should == Log4r::DEBUG
  end

  it 'can be reset' do
    @logger.level = Log4r::FATAL
    current_log = @logger.level
    Aesop::Logger.reset
    @logger.level.should_not == current_log
  end

  it 'is able to use various log levels' do
    @logger.level = Log4r::DEBUG
    debug = @logger.debug("debug test message")
    debug.should be_an Array
    debug.select{|e| e.is_a?(Log4r::StdoutOutputter)}.should_not be_empty

    info = @logger.info("info test message")
    info.should be_an Array
    info.select{|e| e.is_a?(Log4r::StdoutOutputter)}.should_not be_empty

    warn = @logger.warn("warning test message")
    warn.should be_an Array
    warn.select{|e| e.is_a?(Log4r::StdoutOutputter)}.should_not be_empty

    err = @logger.error("error test message")
    err.should be_an Array
    err.select{|e| e.is_a?(Log4r::StdoutOutputter)}.should_not be_empty

    fatal = @logger.fatal("fatal test message")
    fatal.should be_an Array
    fatal.select{|e| e.is_a?(Log4r::StdoutOutputter)}.should_not be_empty
  end
end

