# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'concord/version'

Gem::Specification.new do |spec|
  spec.name          = 'concord'
  spec.version       = Concord::VERSION
  spec.authors       = ['Matt Huggins']
  spec.email         = ['matt.huggins@kapost.com.com']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://gems.kapost.com'
  end

  spec.summary       = %q{Kapost notification pub/sub and message queue processing.}
  spec.description   = %q{Amazon SNS publishing and SQS queue processing.}
  spec.homepage      = 'https://github.com/kapost/concord'
  spec.license       = 'Proprietary'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fog-aws', '~> 0.4'
  spec.add_dependency 'virtus', '~> 1.0'

  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
end
