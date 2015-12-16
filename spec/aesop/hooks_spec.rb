require File.join( File.dirname(__FILE__), '..', 'spec_helper')

describe 'Creating Hooks' do
  let(:fake_class){ Class.new }

  before :each do
    Aesop.send(:remove_const, :MerbBootLoader) if Aesop.const_defined?(:MerbBootLoader)
    Aesop.send(:remove_const, :Railtie) if Aesop.const_defined?(:Railtie)
  end

  def load_file
    load File.join( File.dirname(__FILE__), '..', '..', 'lib', 'aesop.rb')
  end

  context 'Merb' do
    def stub_merb_constants
      stub_const('Merb', fake_class)
      stub_const('Merb::BootLoader', fake_class)
      stub_const('Merb::BootLoader::ChooseAdapter', fake_class)
    end

    it 'does not define a merb bootloader when merb does not exist' do
      Aesop.should_not have_constant(:MerbBootLoader)
    end

    it 'defines a merb bootloader when Merb and a Merb::Bootloader exist' do
      fake_class.stub(:after)
      stub_merb_constants
      load_file
      Aesop.should have_constant(:MerbBootLoader)
    end
  end

  context 'Rails' do
    def stub_rails_constants
      stub_const('Rails', fake_class)
      stub_const('Rails::Railtie', fake_class)
    end

    before :each do
      fake_class.stub(:initializer)
    end

    it 'does not define a railtie when rails does not exist' do
      Aesop.should_not have_constant(:Railtie)
    end

    it 'defines a railtie when Rails exists and its version is > 3' do
      stub_rails_constants
      fake_class.stub(:version).and_return('3.1')
      load_file
      Aesop.should have_constant(:Railtie)
    end

    context 'Rails < 3' do
      before :each do
        stub_rails_constants
        fake_class.stub(:version).and_return('2.9')
      end

      it 'does not define a railtie when Rails exists and its version < 3' do
        load_file
        Aesop.should_not have_constant(:Railtie)
      end

      it 'inits Aesop when Rails exists' do
        Aesop::Aesop.instance.should_receive(:init)
        load_file
      end
    end
  end

  context 'Other' do
    it 'does not init' do
      expect(Aesop::Aesop.instance).to_not receive(:init)
      load_file
    end
  end
end
