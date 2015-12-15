source 'https://rubygems.org'

# Specify your gem's dependencies in aesop.gemspec
gemspec

gem "configatron", :github => 'jwkoelewijn/configatron'

group :test do
  gem "codeclimate-test-reporter",  :require => false
  gem "simplecov",                  :require => false
  gem "capistrano-spec"
  gem "capistrano", "~> 2.14.2"

  if RUBY_VERSION < '2.0'
    gem 'net-ssh', '~> 2.9'
  end
end
