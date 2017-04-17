require 'rubygems/dependency_installer'

di = Gem::DependencyInstaller.new

begin
  if RUBY_VERSION < '2.0'
    puts "Installing net-ssh v2.9.x for Ruby #{RUBY_VERSION}"
    di.install 'net-ssh', '~> 2.9'
  end
rescue => e
  warn "#{$0}: #{e}"
  exit!
end
