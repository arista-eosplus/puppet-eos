require 'bundler/gem_tasks'
require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'ci/reporter/rake/rspec'
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'pkg/**/*.pp']

desc 'Prep CI RSpec tests'
task :ci_prep do
  require 'rubygems'
  begin
    gem 'ci_reporter'
    require 'ci/reporter/rake/rspec'
    ENV['CI_REPORTS'] = 'results'
  rescue LoadError
    puts 'Missing ci_reporter gem. You must have the ci_reporter gem installed'\
         ' to run the CI spec tests'
  end
end

desc 'Run the CI RSpec tests'
task ci_spec: [:ci_prep, 'ci:setup:rspec', :spec]

desc 'Validate manifests, templates, and ruby files'
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb', 'lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ %r{spec\/fixtures}
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

desc 'Generate Getting Started Guide HTML'
task :guide do
  system 'make -C guide html'
end

desc 'Clean Getting Started docs'
task :guide_clean do
  system 'make -C guide clean'
end
