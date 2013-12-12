require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

unless RUBY_VERSION == "1.8.7"
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start

  require 'simplecov'
  SimpleCov.start
end

require 'rspec/core'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'aesop'

def config
  configatron
end

def remove_deploy_file
  if File.exist?(config.deployment_file)
    File.delete(config.deployment_file)
  end
end

def create_deploy_file(timestamp = Time.now)
  remove_deploy_file
  File.open(config.deployment_file, 'w') do |file|
    file.write(timestamp.to_i)
  end
end

RSpec::Matchers.define :have_constant do |const|
  match do |owner|
    owner.const_defined?(const)
  end
end
