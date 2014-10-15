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
require 'puppet_x/eos/eapi'

Puppet::Type.type(:eos_static_route).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show running-config section ip route', format: 'text')
    result = resp.first['output']
    
    result.split(/\n/).map do |entry|
      parts = entry.split()
      provider_hash = { name: parts[2], ensure: :present }
      provider_hash[:next_hop] = parts[3]
      provider_hash[:route_name] = ''
      new(provider_hash)
    end
  end

  def self.prefetch(resources)
    provider_hash = instances.each_with_object({}) do |provider, hsh|
      hsh[provider.name] = provider
    end

    resources.each_pair do |name, resource|
      resource.provider = provider_hash[name] if provider_hash[name]
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

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    prefix = resource[:name]
    next_hop = resource[:next_hop]
    eapi.config(["ip route #{prefix} #{next_hop}"])
    @property_hash = { name: prefix, ensure: :present }
    self.hext_hop = resource[:next_hop] if resource[:next_hop]
    self.route_name = resource[:route_name] if resource[:route_name]
  end

  def destroy
    prefix = resource[:name]
    eapi.config(["no ip route #{prefix}"])
    @property_hash = { name: prefix, ensure: :absent }
  end

  def flush
    flush_next_hop
    @property_hash = resource.to_hash
  end

  def flush_next_hop
    prefix = resource[:name]
    hext_hop = resource[:next_hop]
    new_next_hop = @property_flush[:next_hop]
    eapi.config(["no ip route #{prefix} #{next_hop}", "ip route #{prefix} #{new_next_hop}"])#
  end

end

