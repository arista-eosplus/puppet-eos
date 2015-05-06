# encoding: utf-8

require 'pathname'
require 'yaml'
require 'json'

##
# Fixtures implements a global container to store fixture data loaded from the
# filesystem.
class Fixtures
  def self.[](name)
    @fixtures[name]
  end

  def self.[]=(name, value)
    @fixtures[name] = value
  end

  def self.clear
    @fixtures = {}
  end

  clear

  ##
  # save an object and saves it as a fixture in the filesystem.
  #
  # @param [Symbol] key The fixture name without the `fixture_` prefix or
  #   `.json` suffix.
  #
  # @param [Object] obj The object to serialize to JSON and write to the
  #   fixture file.
  #
  # @option opts [String] :dir ('/path/to/fixtures') The fixtures directory,
  #   defaults to the full path of spec/fixtures/ relative to the root of the
  #   module.
  def self.save(key, obj, opts = {})
    dir = opts[:dir] || File.expand_path('../../fixtures', __FILE__)
    file = Pathname.new(File.join(dir, "fixture_#{key}.yaml"))
    fail ArgumentError, "Error, file #{file} exists" if file.exist?
    File.open(file, 'w+') { |f| f.puts YAML.dump(obj) }
  end
end

##
# FixtureHelpers provides instance methods for RSpec test cases that aid in the
# loading and caching of fixture data.
module FixtureHelpers
  ##
  # fixture loads a JSON fixture from the spec/fixtures/ directory, prefixed
  # with fixture_.  Given the name 'foo' the file
  # `spec/fixtures/fixture_foo.json` will be loaded and returned.  This method
  # is memoized across the life of the process.
  #
  # @param [Symbol] key The fixture name without the `fixture_` prefix or
  #   `.json` suffix.
  #
  # @option opts [String] :dir ('/path/to/fixtures') The fixtures directory,
  #   defaults to the full path of spec/fixtures/ relative to the root of the
  #   module.
  def fixture(key, opts = {})
    memo = Fixtures[key]
    return memo if memo
    dir = opts[:dir] || File.expand_path('../../fixtures', __FILE__)

    yaml = Pathname.new(File.join(dir, "fixture_#{key}.yaml"))
    json = Pathname.new(File.join(dir, "fixture_#{key}.json"))

    Fixtures[key] = if yaml.exist?; then YAML.load(File.read(yaml))
                    elsif json.exist?; then JSON.load(File.read(json))
                    else fail "could not load YAML or JSON fixture #{key}"
                    end
  end
end
