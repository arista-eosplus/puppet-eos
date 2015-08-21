#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
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
require 'puppet/type'
require 'pathname'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/eos/provider'

Puppet::Type.type(:eos_staticroute).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    routes = node.api('staticroutes').getall
    routes.each_with_object([]) do |attrs, arry|
      name = namevar(attrs[:destination], attrs[:nexthop])
      provider_hash = { name: name, ensure: :present }
      provider_hash[:route_name] = attrs[:name] if attrs[:name]
      provider_hash[:distance] = attrs[:distance] if attrs[:distance]
      provider_hash[:tag] = attrs[:tag] if attrs[:tag]
      arry << new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def next_hop=(val)
    @property_flush[:next_hop] = val
  end

  def route_name=(val)
    @property_flush[:route_name] = val
  end

  def distance=(val)
    @property_flush[:distance] = val
  end

  def tag=(val)
    @property_flush[:tag] = val
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

  def flush
    desired_state = @property_hash.merge!(@property_flush)
    # Extract the destination and next_hop from the name
    comp = desired_state[:name].split('/')
    dest = "#{comp[0]}/#{comp[1]}"
    next_hop = comp[2]

    opts = {}
    opts[:distance] = desired_state[:distance]
    opts[:route_name] = desired_state[:route_name]
    opts[:tag] = desired_state[:tag]

    api = node.api('staticroutes')
    case desired_state[:ensure]
    when :present
      api.create(dest, next_hop, opts)
    when :absent
      api.delete(dest, next_hop)
    end
    @property_hash = desired_state
  end

  def self.namevar(destination, nexthop)
    "#{destination}/#{nexthop}"
  end
end
