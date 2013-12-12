require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe "Aesop::Merb::MerbBootLoader" do
  let(:fake_class){ Class.new }

  def load_class
    load File.join( File.dirname(__FILE__), '..', '..', '..', 'lib', 'aesop', 'merb', 'merb_boot_loader.rb')
  end

  before :each do
    stub_const('Merb', fake_class)
    stub_const('Merb::BootLoader', fake_class)
    stub_const('Merb::BootLoader::ChooseAdapter', fake_class)
  end

  it 'inserts after the choose adapter' do
    fake_class.should_receive(:after).with(Merb::BootLoader::ChooseAdapter)
    load_class
  end

  it 'initializes aesop' do
    Aesop::Aesop.instance.should_receive(:init)
    Aesop::MerbBootLoader.run
  end
end
