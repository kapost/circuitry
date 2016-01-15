# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circuitry/version'

Gem::Specification.new do |spec|
  spec.name          = 'circuitry'
  spec.version       = Circuitry::VERSION
  spec.authors       = ['Matt Huggins']
  spec.email         = ['matt.huggins@kapost.com']

  spec.summary       = %q{Kapost notification pub/sub and message queue processing.}
  spec.description   = %q{Amazon SNS publishing and SQS queue processing.}
  spec.homepage      = 'https://github.com/kapost/circuitry'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'retries', '~> 0.0.5'
  spec.add_dependency 'virtus', '~> 1.0'
  s.add_dependency "rails", "~> 4.2.5"

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'connection_pool'
  spec.add_development_dependency 'dalli'
  spec.add_development_dependency 'memcache_mock'
  spec.add_development_dependency 'mock_redis'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'thor'
end
