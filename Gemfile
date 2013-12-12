source 'https://rubygems.org'

# Specify your gem's dependencies in aesop.gemspec
gemspec

gem "configatron", :git => 'git@github.com:jwkoelewijn/configatron.git'

group :test do
  gem "codeclimate-test-reporter",  :require => false
  gem "simplecov",                  :require => false
  gem "capistrano-spec"
  gem "capistrano", "~> 2.14.2"
end
