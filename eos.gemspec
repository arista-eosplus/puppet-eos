# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eos/version'

Gem::Specification.new do |spec|
  spec.name          = 'arista-eos'
  spec.version       = Eos::VERSION
  spec.authors       = ['Peter Sprygada', 'John Corbin']
  spec.email         = ['sprygada@arista.com', 'jcorbin@arista.com']
  spec.description   = %q{Arista EOS provides Puppet modules to configure EOS devices}
  spec.summary       = %q{Type and provider implementation for Arista EOS devices}
  spec.homepage      = 'https://github.com/arista-eosplus/swisscom'
  spec.license       = 'BSD-3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Development
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry'
  # Testing
  spec.add_development_dependency 'rspec-puppet'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'puppetlabs_spec_helper'
  spec.add_development_dependency 'simplecov'

  spec.add_dependency 'puppet'
end
