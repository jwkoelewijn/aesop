require "capistrano"
require "capistrano-spec"
require File.join( File.dirname(__FILE__), '..', '..', 'recipes', 'aesop.rb')

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end

describe Aesop::Capistrano, "loaded into a configuration" do
  let(:config){ Capistrano::Configuration.new }
  let(:task_name){ "aesop:record_deployment" }

  before :each do
    config.extend(Capistrano::Spec::ConfigurationExtension)
    config.load("deploy")
    config.set(:application, 'aesop')
    config.set(:repository, 'aesop')
    Aesop::Capistrano.load_into(config)
  end

  it 'defines the record_deployment task' do
    config.find_task(task_name).should_not be_nil
  end

  it 'defines the task only for app server roles' do
    task = config.find_task(task_name)
    options = task.options
    options.should have_key(:roles)
    options[:roles].should == :app
  end

  it 'sets the deployment_time variable' do
    config.find_and_execute_task(task_name)
    config.fetch(:deployment_time).should_not be_nil
  end

  it 'uploads a file called defined in the configuration' do
    config.set(:release_path, '/release_path')
    config.find_and_execute_task(task_name)
    config.should have_put(config.fetch(:deployment_time)).to("#{config.fetch(:release_path)}/DEPLOY_TIME")
  end

  it 'executes after the deploy:finalize task' do
    config.should callback(task_name).after("deploy:finalize_update")
  end
end
