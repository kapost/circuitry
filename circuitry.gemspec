# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'circuitry/version'

Gem::Specification.new do |spec|
  spec.name          = 'circuitry'
  spec.version       = Circuitry::VERSION
  spec.authors       = ['Matt Huggins', 'Brandon Croft']
  spec.email         = ['matt.huggins@kapost.com', 'brandon@kapost.com']

  spec.summary       = 'Decouple ruby applications using Amazon SNS fanout with SQS processing.'
  spec.description   = 'A Circuitry publisher application can broadcast events which can be processed independently by Circuitry subscriber applications.'
  spec.homepage      = 'https://github.com/kapost/circuitry'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'retries', '~> 0.0.5'
  spec.add_dependency 'virtus', '~> 1.0'
  spec.add_dependency 'thor'

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
end
