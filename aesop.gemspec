# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aesop/version'

Gem::Specification.new do |spec|
  spec.name          = "aesop"
  spec.version       = Aesop::VERSION
  spec.authors       = ["J.W. Koelewijn"]
  spec.email         = ["jwkoelewijn@gmail.com"]
  spec.description   = %q{Check deployment time, write it to Redis and when exceptions are thrown, check if it should send notification}
  spec.summary       = %q{Manage exception notification}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "redis"
  spec.add_dependency "hiredis"
  spec.add_dependency "configatron"
  spec.add_dependency "log4r"
end
