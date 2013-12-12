require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe "Aesop::Rails::Railtie" do
  let(:fake_class){ Class.new }
  let(:fake_app){ double }

  def load_class
    load File.join( File.dirname(__FILE__), '..', '..', '..', 'lib', 'aesop', 'rails', 'railtie.rb')
  end

  before :each do
    stub_const('Rails', fake_class)
    stub_const('Rails::Railtie', fake_class)
  end

  after :each do
    Aesop.send(:remove_const, :Railtie) if Aesop.const_defined?(:Railtie)
  end

  it 'defines an initializer' do
    fake_class.should_receive(:initializer)
    load_class
  end

  it 'initializes aesop in the railtie initializer' do
    middleware = double
    middleware.stub(:insert_after)
    config = double
    config.stub(:middleware).and_return(middleware)
    fake_app.stub(:config).and_return(config)
    Aesop::Aesop.instance.should_receive(:init)
    fake_class.stub(:initializer) do |name, &blk|
      blk.call(fake_app)
    end
    load_class
  end

  context 'Inserting middleware' do
    let(:middleware){ double }

    before :each do
      config = double
      config.stub(:middleware).and_return(middleware)
      fake_app.stub(:config).and_return(config)
      fake_class.stub(:initializer) do |name, &blk|
        blk.call(fake_app)
      end
    end

    it 'inserts middleware after DebugExceptions if it exists' do
      stub_const('ActionDispatch', fake_class)
      stub_const('ActionDispatch::DebugExceptions', fake_class)
      middleware.should_receive(:insert_after).with("ActionDispatch::DebugExceptions", "Aesop::Rails::Middleware")
      load_class
    end

    it 'inserts middleware after ShowExceptions if DebugExceptions does not exist' do
      middleware.should_receive(:insert_after).with("ActionDispatch::ShowExceptions", "Aesop::Rails::Middleware")
      load_class
    end
  end
end
