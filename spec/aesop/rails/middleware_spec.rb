require File.join( File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Aesop::Rails::Middleware do
  let(:fake_app){ double }
  let(:exception){ Exception.new }
  subject { Aesop::Rails::Middleware.new( fake_app ) }

  it 'dispatches exceptions from the middleware stack to aesop' do
    fake_app.stub(:call).with(anything()){ raise exception }
    Aesop::Aesop.instance.should_receive(:catch_exception).with(exception)
    subject.call(:production)
  end
end
