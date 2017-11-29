source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place, fake_version = nil)
  mdata = /^(git[:@][^#]*)#(.*)/.match(place)
  if mdata
    hsh = { git: mdata[1], branch: mdata[2], require: false }
    return [fake_version, hsh].compact
  end
  mdata2 = %r{^file:\/\/(.*)}.match(place)
  if mdata2
    return ['>= 0', { path: File.expand_path(mdata2[1]), require: false }]
  end
  [place, { require: false }]
end

gem 'inifile'
gem 'netaddr'

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-shell'
end

group :development, :test do
  gem 'ci_reporter'
  gem 'ci_reporter_rspec'
  gem 'kitchen-vagrant'
  gem 'metadata-json-lint', require: false
  gem 'pry',                     require: false
  gem 'pry-doc',                 require: false
  gem 'puppet-lint'
  gem 'puppetlabs_spec_helper'
  gem 'rake', '~> 10.1.0', require: false
  gem 'redcarpet', '~> 3.1.2'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-mocks', '~> 3.0.0'
  gem 'simplecov',               require: false
  gem 'simplecov-json',          require: false
  gem 'simplecov-rcov',          require: false
  gem 'test-kitchen'
  gem 'yard'
end

ENV['GEM_PUPPET_VERSION'] ||= ENV['PUPPET_GEM_VERSION']
puppetversion = ENV['GEM_PUPPET_VERSION']
if puppetversion
  gem 'puppet', *location_for(puppetversion)
else
  # Rubocop thinks these are duplicates.
  # rubocop:disable Bundler/DuplicatedGem
  gem 'puppet', require: false
  # rubocop:enable Bundler/DuplicatedGem
end

rbeapiversion = ENV['GEM_RBEAPI_VERSION']
if rbeapiversion
  gem 'rbeapi', *location_for(rbeapiversion)
else
  # Rubocop thinks these are duplicates.
  # rubocop:disable Bundler/DuplicatedGem
  gem 'rbeapi', require: false
  # rubocop:enable Bundler/DuplicatedGem
end

# Ensure this remains usable with Ruby 1.9
if RUBY_VERSION.to_f < 2.0
  gem 'json', '< 2.0'
  group :development, :test do
    gem 'listen', '< 3.1.0'
    gem 'rubocop', '>=0.35.1', '< 0.38'
  end
else
  # Rubocop thinks these are duplicates.
  # rubocop:disable Bundler/DuplicatedGem
  gem 'json'
  group :development, :test do
    gem 'rubocop', '>= 0.49.0'
  end
  # rubocop:enable Bundler/DuplicatedGem
end

# vim:ft=ruby
