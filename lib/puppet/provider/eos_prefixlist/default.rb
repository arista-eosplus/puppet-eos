#
# Copyright (c) 2016, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# encoding: utf-8
require 'puppet/type'
require 'pathname'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/eos/provider'

Puppet::Type.type(:eos_prefixlist).provide(:eos) do
  desc 'Manage prefix lists on Arista EOS. Requires rbeapi rubygem.'
  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  # rubocop:disable Metrics/MethodLength
  def self.instances
    result = node.api('prefixlists').getall
    return [] if !result || result.empty?
    result.each_with_object([]) do |(prefix_list, rules), arry|
      rules.each do |rule|
        attrs = parse_prefix(rule['prefix'])
        provider_hash = {
          :name => namevar(prefix_list: prefix_list, seqno: rule['seq']),
          :ensure => :present
        }
        provider_hash[:prefix_list] = prefix_list
        provider_hash[:seqno] = rule['seq'].to_i
        provider_hash[:action] = rule['action']
        provider_hash[:prefix] = attrs[:prefix]
        provider_hash[:masklen] = attrs[:masklen].to_i
        provider_hash[:eq] = attrs[:eq].to_i if attrs[:eq]
        provider_hash[:ge] = attrs[:ge].to_i if attrs[:ge]
        provider_hash[:le] = attrs[:le].to_i if attrs[:le]
        Puppet.debug(provider_hash)
        arry << new(provider_hash)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush = resource.to_hash
  end

  def destroy
    @property_flush = resource.to_hash
  end

  def prefix_list=(val)
    @property_flush[:prefix_list] = val
  end

  def seqno=(val)
    @property_flush[:seqno] = val
  end

  def action=(val)
    @property_flush[:action] = val
  end

  def prefix=(val)
    @property_flush[:prefix] = val
  end

  def masklen=(val)
    @property_flush[:masklen] = val
  end

  def eq=(val)
    @property_flush[:eq] = val
  end

  def ge=(val)
    @property_flush[:ge] = val
  end

  def le=(val)
    @property_flush[:le] = val
  end

  def flush
    api = node.api('prefixlists')
    desired_state = @property_hash.merge!(@property_flush)
    desired_state[:prefix_list] ||= resource[:name].partition(':').first
    desired_state[:seqno] ||= resource[:name].partition(':').last.to_i
    name = desired_state[:prefix_list]
    seqno = desired_state[:seqno]
    action = resource[:action]
    prefix = "#{resource[:prefix]}/#{resource[:masklen]}"
    prefix << ' eq #{resource[:eq]}' if resource[:eq]
    prefix << ' ge #{resource[:ge]}' if resource[:ge]
    prefix << ' eq #{resource[:le]}' if resource[:le]

    validate_identity(desired_state)
    case desired_state[:ensure]
    when :present
      api.add_rule(name, action, prefix, seqno)
    when :absent
      api.delete(name, seqno)
    end
    @property_hash = desired_state
  end

  def validate_identity(opts = {})
    @doc = <<-EOS
      Make sure 'prefix_list' and 'seqno' are specified in
      order to uniquely identify the prefix list resource.
    EOS

    errors = false # rubocop:disable Lint/UselessAssignment
    missing = [:prefix_list, :seqno].reject { |k| opts[k] }
    errors = !missing.empty?
    msg = "Invalid options #{opts.inspect} missing: #{missing.join(', ')}"
    fail Puppet::Error, msg if errors
  end
  private :validate_identity

  def self.namevar(opts)
    name = opts[:prefix_list]
    seqno = opts[:seqno]
    "#{name}:#{seqno}"
  end

  def self.parse_prefix(prefix)
    regex = %r{
            ^([^\/]+)\/               # prefix
            (\d+)                     # masklen
            (\s([^\s]+)\s([\d]+))?    # first comparison operator
            (\s([^\s]+)\s([\d]+))?$   # second comparison operator
            }x

    groups = prefix.match(regex)
    {}.tap do |attrs|
      attrs[:prefix] = groups[1]
      attrs[:masklen] = groups[2]
      # comparison operators
      attrs[groups[4].to_sym] = groups[5] if groups[4]
      attrs[groups[7].to_sym] = groups[8] if groups[7]
    end
  end
end
